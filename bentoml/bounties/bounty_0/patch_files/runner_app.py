from __future__ import annotations

import functools
import json
import logging
import pickle
import traceback
import typing as t
from typing import TYPE_CHECKING

from simple_di import Provide
from simple_di import inject

from bentoml.exceptions import BentoMLException
from bentoml.exceptions import ServiceUnavailable

from ..configuration.containers import BentoMLContainer
from ..context import server_context
from ..context import trace_context
from ..marshal.dispatcher import CorkDispatcher
from ..runner.container import AutoContainer
from ..runner.container import Payload
from ..runner.utils import PAYLOAD_META_HEADER
from ..runner.utils import Params
from ..runner.utils import payload_paramss_to_batch_params
from ..server.base_app import BaseAppFactory
from ..types import LazyType
from ..utils import with_app_arg
from ..utils.metrics import exponential_buckets

feedback_logger = logging.getLogger("bentoml.feedback")
logger = logging.getLogger(__name__)

if TYPE_CHECKING:
    from opentelemetry.sdk.trace import Span
    from starlette.applications import Starlette
    from starlette.middleware import Middleware
    from starlette.requests import Request
    from starlette.responses import Response
    from starlette.routing import BaseRoute

    from ..runner.runner import Runner
    from ..runner.runner import RunnerMethod
    from ..types import LifecycleHook

import io
import numpy as np
import pandas as pd
import pathlib
from PIL import Image
import json

class SafeUnpickler(pickle.Unpickler):
    """Custom Unpickler that only allows specific types."""
    def find_class(self, module, name):
        ALLOWED_TYPES = {
            dict, list, str, int, float, bool, np.ndarray,
            pd.DataFrame, pathlib.Path, Image.Image
        }
        obj = getattr(__import__(module, fromlist=[name]), name)
        if obj in ALLOWED_TYPES:
            return obj
        raise pickle.UnpicklingError(f"Disallowed type: {module}.{name}")

def safe_pickle_loads(data):
    # Allow class Param to be pickle loaded
    if b"bentoml._internal.runner.utils" in data and b"Params" in data:
        return pickle.loads(data)
    return SafeUnpickler(io.BytesIO(data)).load()

def is_parquet(data: bytes) -> bool:
    return data[:4] == b"PAR1"

def is_csv(text: str) -> bool:
    try:
        pd.read_csv(io.StringIO(text))
        return True
    except Exception:
        return False

def generic_loads(data: bytes):
    """
    Generic deserialization function that auto-detects format:
      - If bytes → Check for JSON, CSV, Parquet, Pickle
      - If none match → Return raw bytes
    """
    # 1) Try decoding as UTF-8 first to check for JSON or CSV
    try:
        decoded_str = data.decode('utf-8')
        try:
            return json.loads(decoded_str)
        except json.JSONDecodeError:
            pass  
        # Try CSV
        if is_csv(decoded_str):
            return pd.read_csv(io.StringIO(decoded_str))
    except UnicodeDecodeError:
        pass 

    if is_parquet(data):
        return pd.read_parquet(io.BytesIO(data))
    try:
        return safe_pickle_loads(data)
    except pickle.UnpicklingError:
        pass  

    raise ValueError("Unsupported data type. Must be str (JSON/CSV) or bytes (Pickle/Parquet).")

class RunnerAppFactory(BaseAppFactory):
    @inject
    def __init__(
        self,
        runner: Runner,
        worker_index: int = 0,
        enable_metrics: bool = Provide[BentoMLContainer.runners_config.metrics.enabled],
    ) -> None:
        self.runner = runner
        self.worker_index = worker_index
        self.enable_metrics = enable_metrics

        self.dispatchers: dict[str, CorkDispatcher[Params[Payload], t.Any]] = {}

        runners_config = BentoMLContainer.runners_config.get()
        traffic = runners_config.get("traffic", {}).copy()
        if runner.name in runners_config:
            traffic.update(runners_config[runner.name].get("traffic", {}))
        super().__init__(
            timeout=traffic["timeout"], max_concurrency=traffic["max_concurrency"]
        )

        def fallback():
            return ServiceUnavailable("process is overloaded")

        for method in runner.runner_methods:
            max_batch_size = method.max_batch_size if method.config.batchable else -1
            if max_batch_size > 1:
                self.dispatchers[method.name] = CorkDispatcher(
                    max_latency_in_ms=method.max_latency_ms,
                    max_batch_size=max_batch_size,
                    fallback=fallback,
                    batch_dim=method.config.batch_dim,
                )

    @property
    def name(self) -> str:
        return self.runner.name

    def _init_metrics_wrappers(self, _: Starlette) -> None:
        metrics_client = BentoMLContainer.metrics_client.get()

        max_max_batch_size = max(
            method.max_batch_size for method in self.runner.runner_methods
        )

        self.adaptive_batch_size_hist = metrics_client.Histogram(
            namespace="bentoml_runner",
            name="adaptive_batch_size",
            documentation="Runner adaptive batch size",
            labelnames=[
                "runner_name",
                "worker_index",
                "method_name",
                "service_version",
                "service_name",
            ],
            buckets=exponential_buckets(1, 2, max_max_batch_size),
        )

    @property
    def on_startup(self) -> list[LifecycleHook]:
        on_startup = super().on_startup
        on_startup.insert(
            0, with_app_arg(functools.partial(self.runner.init_local, quiet=True))
        )
        on_startup.insert(0, self._init_metrics_wrappers)

        return on_startup

    @property
    def on_shutdown(self) -> list[LifecycleHook]:
        on_shutdown: list[LifecycleHook] = [with_app_arg(self.runner.destroy)]
        for dispatcher in self.dispatchers.values():
            on_shutdown.append(with_app_arg(dispatcher.shutdown))
        on_shutdown.extend(super().on_shutdown)
        return on_shutdown

    @property
    def routes(self) -> t.List[BaseRoute]:
        """
        Setup routes for Runner server, including:

        /healthz        liveness probe endpoint
        /readyz         Readiness probe endpoint
        /metrics        Prometheus metrics endpoint

        For method in self.runner.runner_methods:
        /{method.name}  Run corresponding runnable method
        /               Run the runnable method "__call__" if presented
        """
        from starlette.routing import Route

        routes = super().routes
        for method in self.runner.runner_methods:
            path = "/" if method.name == "__call__" else "/" + method.name
            routes.append(
                Route(
                    path=path,
                    endpoint=self._mk_request_handler(method, method.config.batchable),
                    methods=["POST"],
                )
            )
        return routes

    @property
    def middlewares(self) -> list[Middleware]:
        middlewares = super().middlewares

        from opentelemetry.instrumentation.asgi import OpenTelemetryMiddleware
        from starlette.middleware import Middleware

        def client_request_hook(span: Span | None, *_: t.Any) -> None:
            if span is not None:
                trace_context.request_id = span.context.span_id

        middlewares.append(
            Middleware(
                OpenTelemetryMiddleware,
                excluded_urls=BentoMLContainer.tracing_excluded_urls.get(),
                default_span_details=None,
                server_request_hook=None,
                client_request_hook=client_request_hook,
                tracer_provider=BentoMLContainer.tracer_provider.get(),
            )
        )

        if self.enable_metrics:
            from .http.instruments import RunnerTrafficMetricsMiddleware

            middlewares.append(Middleware(RunnerTrafficMetricsMiddleware))

        access_log_config = BentoMLContainer.runners_config.logging.access
        if access_log_config.enabled.get():
            from .http.access import AccessLogMiddleware

            access_logger = logging.getLogger("bentoml.access")
            if access_logger.getEffectiveLevel() <= logging.INFO:
                middlewares.append(
                    Middleware(
                        AccessLogMiddleware,
                        has_request_content_length=access_log_config.request_content_length.get(),
                        has_request_content_type=access_log_config.request_content_type.get(),
                        has_response_content_length=access_log_config.response_content_length.get(),
                        has_response_content_type=access_log_config.response_content_type.get(),
                    )
                )

        return middlewares

    def _mk_request_handler(
        self,
        runner_method: RunnerMethod[t.Any, t.Any, t.Any],
        batching: bool = True,
    ) -> t.Callable[[Request], t.Coroutine[None, None, Response]]:
        from starlette.responses import Response

        server_str = f"BentoML-Runner/{self.runner.name}/{runner_method.name}/{self.worker_index}"

        if runner_method.config.is_stream:
            # Streaming does not have batching implemented yet
            async def infer(
                params: Params[t.Any],
            ) -> t.Coroutine[None, None, t.AsyncGenerator[str, None]]:
                async def inner():
                    # This is a workaround to allow infer stream to return a iterable of
                    # async generator, to align with how non stream inference works
                    param = params.map(AutoContainer.from_payload)
                    try:
                        ret = runner_method.async_stream(*param.args, **param.kwargs)
                    except Exception:
                        traceback.print_exc()
                        raise
                    async for data in ret:
                        yield data

                return inner()
        else:
            if runner_method.name in self.dispatchers:

                async def infer_batch(
                    params_list: t.Sequence[Params[t.Any]],
                ) -> list[Payload] | list[tuple[Payload, ...]]:
                    self.adaptive_batch_size_hist.labels(  # type: ignore
                        runner_name=self.runner.name,
                        worker_index=self.worker_index,
                        method_name=runner_method.name,
                        service_version=server_context.bento_version,
                        service_name=server_context.bento_name,
                    ).observe(len(params_list))

                    if not params_list:
                        return []

                    input_batch_dim, output_batch_dim = runner_method.config.batch_dim

                    batched_params, indices = payload_paramss_to_batch_params(
                        params_list, input_batch_dim
                    )

                    try:
                        batch_ret = await runner_method.async_run(
                            *batched_params.args, **batched_params.kwargs
                        )
                    except Exception:
                        traceback.print_exc()
                        raise

                    # multiple output branch
                    if LazyType["tuple[t.Any, ...]"](tuple).isinstance(batch_ret):
                        output_num = len(batch_ret)
                        payloadss = tuple(
                            AutoContainer.batch_to_payloads(
                                batch_ret[idx], indices, batch_dim=output_batch_dim
                            )
                            for idx in range(output_num)
                        )
                        ret = list(zip(*payloadss))
                        return ret

                    # single output branch
                    payloads = AutoContainer.batch_to_payloads(
                        batch_ret,
                        indices,
                        batch_dim=output_batch_dim,
                    )
                    return payloads

                infer = self.dispatchers[runner_method.name](infer_batch)
            else:

                async def infer(params: Params[t.Any]) -> Payload:
                    params = params.map(AutoContainer.from_payload)

                    try:
                        ret = await runner_method.async_run(
                            *params.args, **params.kwargs
                        )
                    except Exception:
                        traceback.print_exc()
                        raise

                    return AutoContainer.to_payload(ret, 0)

        async def _request_handler(request: Request) -> Response:
            assert self._is_ready

            arg_num = int(request.headers["args-number"])
            r_: bytes = await request.body()

            if arg_num == 1:
                params: Params[t.Any] = _deserialize_single_param(request, r_)

            else:
                try:
                    params = generic_loads(r_)
                except Exception as e:
                    return Response(status_code=400, content=f"Invalid input format: {str(e)}")
            try:
                payload = await infer(params)
            except BentoMLException as e:
                # pass known exceptions to the client
                return Response(
                    status_code=e.error_code,
                    content=str(e),
                    headers={
                        PAYLOAD_META_HEADER: "{}",
                        "Content-Type": "application/vnd.bentoml.error",
                        "Server": server_str,
                    },
                )

            if isinstance(payload, ServiceUnavailable):
                return Response(
                    "Service Busy",
                    status_code=payload.error_code,
                    headers={
                        PAYLOAD_META_HEADER: json.dumps({}),
                        "Content-Type": "application/vnd.bentoml.error",
                        "Server": server_str,
                    },
                )
            if isinstance(payload, Payload):
                return Response(
                    payload.data,
                    headers={
                        PAYLOAD_META_HEADER: json.dumps(payload.meta),
                        "Content-Type": f"application/vnd.bentoml.{payload.container}",
                        "Server": server_str,
                    },
                )
            if isinstance(payload, tuple):
                # a tuple, which means user runnable has multiple outputs
                return Response(
                    pickle.dumps(payload),
                    headers={
                        PAYLOAD_META_HEADER: json.dumps({}),
                        "Content-Type": "application/vnd.bentoml.multiple_outputs",
                        "Server": server_str,
                    },
                )
            from starlette.responses import StreamingResponse

            if runner_method.config.is_stream:
                return StreamingResponse(
                    stream_encoder(payload),
                    media_type="text/plain",
                    headers={
                        PAYLOAD_META_HEADER: json.dumps({}),
                        "Content-Type": "application/vnd.bentoml.stream_outputs",
                        "Server": server_str,
                    },
                )

            raise BentoMLException(
                f"Unexpected payload type: {type(payload)}, {payload}"
            )

        return _request_handler


async def stream_encoder(
    payload: t.AsyncGenerator[str, None],
) -> t.AsyncGenerator[bytes, None]:
    """
    Extract Data from a AsyncGenerator[str, None]
    """
    async for p in payload:
        yield p.encode("utf-8")


def _deserialize_single_param(request: Request, bs: bytes) -> Params[t.Any]:
    container = request.headers["Payload-Container"]
    meta = json.loads(request.headers["Payload-Meta"])
    batch_size = int(request.headers["Batch-Size"])
    kwarg_name = request.headers.get("Kwarg-Name")
    payload = Payload(
        data=bs,
        meta=meta,
        batch_size=batch_size,
        container=container,
    )
    if kwarg_name:
        d = {kwarg_name: payload}
        params: Params[t.Any] = Params(**d)
    else:
        params: Params[t.Any] = Params(payload)

    return params