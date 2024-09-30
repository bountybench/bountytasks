# Frontend

The frontend service translates various owncloud related HTTP APIs to CS3 requests.

## Endpoints Overview

Currently, the frontend service handles requests for three functionalities, which are `appprovider`, `archiver`, `datagateway` and `ocs`.

### appprovider

The appprovider endpoint, by default `/app`, forwards HTTP requests to the CS3 [App Registry API](https://cs3org.github.io/cs3apis/#cs3.app.registry.v1beta1.RegistryAPI)

### archiver

The archiver endpoint, by default `/archiver`, implements zip and tar download for collections of files. It will internally use the CS3 API to initiate downloads and then stream the individual files as part of a compressed file.

### datagateway

The datagateway endpoint, by default `/data`, forwards file up- and download requests to the correct CS3 data provider. OCIS starts a dataprovider as part of the storage-* services. The routing happens based on the JWT that was created by a storage provider in response to an `InitiateFileDownload` or `InitiateFileUpload` request.

### ocs

The ocs endpoint, by default `/ocs`, implements the ownCloud 10 Open Collaboration Services API by translating it into CS3 API requests. It can handle users, groups, capabilities and also implements the files sharing functionality on top of CS3. The `/ocs/v[12].php/cloud/user/signing-key` is currently handled by the dedicated [ocs](https://github.com/owncloud/ocis/tree/master/services/ocs) service.

### Sharing

Aggregating share information is one of the most time consuming operations in OCIS. The service fetches a list of either received or created shares and has to stat every resource individually. While stats are fast, the default behavior scales linearly with the number of shares.

To save network trips the sharing implementation can cache the stat requests with an in memory cache or in Redis. It will shorten the response time by the network round-trip overhead at the cost of the API only eventually being updated.

Setting `FRONTEND_OCS_RESOURCE_INFO_CACHE_TTL=60` would cache the stat info for 60 seconds. Increasing this value makes sense for large deployments with thousands of active users that keep the cache up to date. Low frequency usage scenarios should not expect a noticeable improvement.

## Scalability

While the frontend service does not persist any data, it does cache information about files and filesystem (`Stat()`) responses and user information. Therefore, multiple instances of this service can be spawned in a bigger deployment like when using container orchestration with Kubernetes, when configuring `FRONTEND_OCS_RESOURCE_INFO_CACHE_STORE` and the related config options.

## Define Read-Only Attributes

A lot of user management is made via the standardized libregraph API. Depending on how the system is configured, there might be some user attributes that an ocis instance admin can't change because of properties coming from an external LDAP server, or similar. This can be the case when the ocis admin is not the LDAP admin. To ease life for admins, there are hints as capabilites telling the frontend which attributes are read-only to enable a different optical representation like being grayed out. To configure these hints, use the environment variable `FRONTEND_READONLY_USER_ATTRIBUTES`, which takes a comma separated list of attributes, see the envvar for supported values.

You can find more details regarding available attributes at the [libre-graph-api openapi-spec](https://github.com/owncloud/libre-graph-api/blob/main/api/openapi-spec/v1.0.yaml) and on [owncloud.dev](https://owncloud.dev/libre-graph-api/).

## Caching

The `frontend` service can use a configured store via `FRONTEND_OCS_STAT_CACHE_STORE`. Possible stores are:
  -   `memory`: Basic in-memory store and the default.
  -   `ocmem`: Advanced in-memory store allowing max size.
  -   `redis`: Stores data in a configured Redis cluster.
  -   `redis-sentinel`: Stores data in a configured Redis Sentinel cluster.
  -   `etcd`: Stores data in a configured etcd cluster.
  -   `nats-js`: Stores data using key-value-store feature of [nats jetstream](https://docs.nats.io/nats-concepts/jetstream/key-value-store)
  -   `noop`: Stores nothing. Useful for testing. Not recommended in production environments.

1.  Note that in-memory stores are by nature not reboot-persistent.
2.  Though usually not necessary, a database name and a database table can be configured for event stores if the event store supports this. Generally not applicable for stores of type `in-memory`. These settings are blank by default which means that the standard settings of the configured store apply.
3.  The frontend service can be scaled if not using `in-memory` stores and the stores are configured identically over all instances.
4.  When using `redis-sentinel`, the Redis master to use is configured via `FRONTEND_OCS_STAT_CACHE_STORE_NODES` in the form of `<sentinel-host>:<sentinel-port>/<redis-master>` like `10.10.0.200:26379/mymaster`.
