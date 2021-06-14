# Fury Kubernetes Keycloak

This repository has all the files needed to deploy KeyCloak in a High Availability cluster. It is composed by all
the `keycloak-{number}` pods in the namespace.

## Requirements

- `kustomize >= 3.10`
- `keycloak > 7.0` (also tested with `Keycloak 4.8.2.Final` see [notes](#considerations-for-keycloak-4.8.2.final) for this case below)
- `kubernetes > 1.18`

## Folder structure

- **examples**: Contains a couple of diferent ways of deploying the KeyCloak cluster:
  - [`h2-tests`](examples/h2-tests): Use only this option to test KeyCloak. It is used in the E2E tests.
  - [`external-cache`](examples/external-cache): Use this setup to run KeyCloak in a cluster across multiple data
  centers.
  - [`keycloak-4.8.2`](examples/keycloak-4.8.2): You should put your custom modifications to the official docker image
  here.
- **katalog**: all the Kubernetes related files to deploy KeyCloak on a cluster.

## Packages

- **[keycloak](#keycloak)**: high availability KeyCloak using native Kubernetes namespace based discovery.
This will form a KeyCloak cluster where the members will be all the KeyCloaks pods in the same Kubernetes namespace.
Version: **7.0.1**.
- **[keycloak-external-cache](#keycloak-external-cache)**: high availability KeyCloak using native Kubernetes namespace
discovery and an external `infinispan` cache cluster for multisite deployments.
- **[infinispan](#infinispan)**: an Infinispan cache cluster deployment, to be used by `keycloak-external-cache`.
Version: **9.3.1.Final**.

## Compatibility

| Module Version / Kubernetes Version | 1.14.X | 1.15.X | 1.16.X |
| ----------------------------------- | :----: | :----: | :----: |
| v1.0.0                              |        |        |        |

- :white_check_mark: Compatible
- :warning: Has issues
- :x: Incompatible

## Configuration

KeyCloak ships with the following options:

- A "keycloak" `StatefulSet` with `1` replica.
- A "keycloak-discovery" `headless service` for the StatefulSet.
- A "keycloak-http" `Service` exposing port `tcp/8080` to access KeyCloak itself.
- A "keycloak" `ServiceAccount` with `list` and `get` permissions on the namespace's `pods` resource.
This service account is needed to use the `KUBE_PING` JGroups discovery method.
- Default credentials to access the admin console:
  - Username: `admin`
  - Password: `admin`

**IMPORTANT:** You probably want to change them, make an overlay of the following environment variables:

```yaml
          - name: KEYCLOAK_USER
            value: "admin"
          - name: KEYCLOAK_PASSWORD
            value: "admin"
```

## Why a StatefulSet?

Because we want to use the pod's name as the value for `jboss.node.name` and `jboss.tx.node.id`,
and both have a hard limit of 27 characters. A podname with the deployment hash has more than 27 characters,
so we use an StatefulSet instead to control the name's length.

## Recommendations

- Set the `replicas` count to your desired number using an overlay.
- It is strongly recommended to use sticky sessions in your ingress definition for keycloak.
**DO NOT** use the cookie `AUTH_SESSION_ID`, because it conflicts with the underlying `mod_cluster`.
We recommend setting it to something else like `INGRESS_SESSION_ID`. See example below:

```yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "INGRESS_SESSION_ID"
  name: keycloak
spec:
  rules:
  - host: sso.domain.io
    http:
      paths:
      - path: /
        backend:
          serviceName: keycloak-http
          servicePort: http
```

- You should use an external database, for example PostgreSQL, to store the persistent data.
You can configure Keycloak to use the database setting the following environment variables:

```yaml
          - name: DB_ADDR
            value: "postgres"
          - name: DB_PORT
            value: "5432"
          - name: DB_DATABASE
            value: "keycloak"
          - name: DB_USER
            value: "keycloak"
          - name: DB_PASSWORD
            value: "password"
```

See the [official documentation for more details](https://hub.docker.com/r/jboss/keycloak).

> ⚠️ If you dont set an external database, keycloak will default to a `H2` local instance on every pod.
> This means that it will not be syncronized between the different keycloak pods.
> ⚠️ On some cases, the Java Virtual Machine (JVM) is configured by default to cache DNS name lookups **forever**
> instead of following the record's TTL. This could be problematic in cases where Keycloak should contact endpoints
> that have "dynamic" DNS entries, for example AWS' RDS endpoint. In order to disable the infit cache, you need to
> pass the `-Dnetworkaddress.cache.ttl=60` flag to the JVM. Where `60` is the TTL in seconds you want to use.
> You can add it to the `JAVA_OPTS` environment variable.

- Set the `CACHE_OWNERS` environment variable, the default value is `1`. This value sets the number of copies that you
want to have of each keycloak's cache. If you have it set to 1, and a pods dies, you'll lose that cache contents.
- The default value for the `liveness` and `readiness` probes is 140 seconds. It could be that your keycloak takes
more time to boot up; adjust the values accordingly to your environment.
- Make sure the ingress you are using forwards the `X-Forwarded-For` and `X-Forwarded-Proto` HTTP headers
and preserving the original `Host` HTTP header. For example, the `nginx-ingress-controller` from versions `0.22.0` and
later has this disabled by default, add this to the `data` field of the ingress `configMap` to enable it:

```yaml
use-forwarded-headers: "true"
```



## Keycloak external cache

### Use case

This type of deployment is for when you want to run Keycloak in a cluster across multiple data centers, most typically using data center sites that are in different geographic regions. When using this mode, each data center will have its own cluster of Keycloak servers.

Eache keycloak cluster connects to an infinispan server and this infinispan server is who sends data to the other cluster via a `hotrod` connection to the others cluster's infinispan.

### External cache configuration

Keycloak will be deployed using the same configuration that for the high availability mode. With the addition of an init script and two more `JAVA_OPTS`:
```yaml
-Dremote.cache.host=infinispan-server-hotrod
-Dkeycloak.connectionsInfinispan.hotrodProtocolVersion=2.8
```

The first one sets the infinispan server address to where each keycloak will connect. The second one sets the protocol version.

Set the `-Dremote.cache.host` parameter to point to the hot-rod port of your infinispan cluster.

> ⚠️ The Infinispan cluster shall be up and running prior booting up Keycloak.

### Infinispan

Besides Keycloak, an additional `infinispan` cluster will be deployed:

- An "infinispan-server" `StatefulSet` with `1` replica.
- An "infinispan-headless" `headless service` for the StatefulSet.
- An "infinispan-http" `Service` that exposes port `tcp/8080` to access infinispan itself.
- An "infinispan-server-hotrod" `Service` that exposes port `tcp/11222` to access infinispan hot rod protocol.
- An "infinispan" `ServiceAccount` with `list` and `get` permissions on the namespace's `pods` resource. This service account is needed in order to use the `KUBE_PING` JGroups discovery method.

In the `cloud-keycloak.xml` configuration file you can find the definition of the keycloaks caches.
