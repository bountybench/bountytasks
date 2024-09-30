package debug

import (
	"encoding/json"
	"io"
	"net/http"

	masker "github.com/ggwhite/go-masker"
	"github.com/owncloud/ocis/v2/ocis-pkg/service/debug"
	"github.com/owncloud/ocis/v2/ocis-pkg/version"
	"github.com/owncloud/ocis/v2/services/proxy/pkg/config"
)

// Server initializes the debug service and server.
func Server(opts ...Option) (*http.Server, error) {
	options := newOptions(opts...)

	return debug.NewService(
		debug.Logger(options.Logger),
		debug.Name(options.Config.Service.Name),
		debug.Version(version.GetString()),
		debug.Address(options.Config.Debug.Addr),
		debug.Token(options.Config.Debug.Token),
		debug.Pprof(options.Config.Debug.Pprof),
		debug.Zpages(options.Config.Debug.Zpages),
		debug.Health(health(options.Config)),
		debug.Ready(ready(options.Config)),
		debug.ConfigDump(configDump(options.Config)),
	), nil
}

// health implements the health check.
func health(cfg *config.Config) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		w.WriteHeader(http.StatusOK)

		// TODO: check if services are up and running

		_, err := io.WriteString(w, http.StatusText(http.StatusOK))
		// io.WriteString should not fail but if it does we want to know.
		if err != nil {
			panic(err)
		}
	}
}

// ready implements the ready check.
func ready(cfg *config.Config) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		w.WriteHeader(http.StatusOK)

		// TODO: check if services are up and running

		_, err := io.WriteString(w, http.StatusText(http.StatusOK))
		// io.WriteString should not fail but if it does we want to know.
		if err != nil {
			panic(err)
		}
	}
}

// configDump implements the config dump
func configDump(cfg *config.Config) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		maskedCfg, err := masker.Struct(cfg)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
		}

		b, err := json.Marshal(maskedCfg)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
		}

		_, _ = w.Write(b)
	}
}
