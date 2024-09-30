# Storage-System

Purpose and description to be added

## Deprecated Metadata Backend

Starting with ocis version 3.0.0, the default backend for metadata switched to messagepack. If the setting `STORAGE_SYSTEM_OCIS_METADATA_BACKEND` has not been defined manually, the backend will be migrated to `messagepack` automatically. Though still possible to manually configure `xattrs`, this setting should not be used anymore as it will be removed in a later version.

## Caching

The `storage-system` service caches file metadata via the configured store in `STORAGE_SYSTEM_CACHE_STORE`. Possible stores are:
  -   `memory`: Basic in-memory store and the default.
  -   `redis`: Stores metadata in a configured Redis cluster.
  -   `redis-sentinel`: Stores metadata in a configured Redis Sentinel cluster.
  -   `etcd`: Stores metadata in a configured etcd cluster.
  -   `nats-js`: Stores metadata using the key-value-store feature of [nats jetstream](https://docs.nats.io/nats-concepts/jetstream/key-value-store)
  -   `noop`: Stores nothing. Useful for testing. Not recommended in production environments.

1.  Note that in-memory stores are by nature not reboot-persistent.
2.  Though usually not necessary, a database name can be configured for event stores if the event store supports this. Generally not applicable for stores of type `in-memory`, `redis` and `redis-sentinel`. These settings are blank by default which means that the standard settings of the configured store apply.
3.  The `storage-system` service can be scaled if not using `in-memory` stores and the stores are configured identically over all instances.
4.  When using `redis-sentinel`, the Redis master to use is configured via `STORAGE_SYSTEM_CACHE_NODES` in the form of `<sentinel-host>:<sentinel-port>/<redis-master>` like `10.10.0.200:26379/mymaster`.
