# KeyCloak

Keycloak is an open source software product to allow single sign-on with Identity and Access Management aimed at
modern applications and services.

- [KeyCloak](#keycloak)
  - [Configuration](#configuration)
    - [Default Credentials](#default-credentials)
    - [Why a StatefulSet?](#why-a-statefulset)
    - [Metrics](#metrics)
    - [Recommendations](#recommendations)
      - [Replicas](#replicas)
      - [Sticky Sessions](#sticky-sessions)
      - [Database](#database)
      - [DNS caching](#dns-caching)
      - [Cache configuration](#cache-configuration)
      - [Liveness And Readiness probes](#liveness-and-readiness-probes)
      - [Be aware of proxy headers](#be-aware-of-proxy-headers)
  - [License](#license)

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

### Default Credentials

You probably want to change them, make an overlay of the following environment variables:

```yaml
          - name: KEYCLOAK_USER
            value: "admin"
          - name: KEYCLOAK_PASSWORD
            value: "admin"
```

### Why a StatefulSet?

Because we want to use the pod's name as the value for `jboss.node.name` and `jboss.tx.node.id`,
and both have a hard limit of 27 characters. A podname with the deployment hash has more than 27 characters,
so we use an StatefulSet instead to control the name's length.

### Metrics

The current package provides access to the metrics exposed by Keycloak, enabled using the env var `KEYCLOAK_STATISTICS=all`. Also, a ServiceMonitor is included, to be attached to [Prometheus Operator](https://github.com/sighupio/fury-kubernetes-monitoring/tree/master/katalog/prometheus-operator).

### Recommendations

#### Replicas

Set the `replicas` count to your desired number using an overlay.

#### Sticky Sessions

It is strongly recommended to use sticky sessions in your ingress definition for keycloak.
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

#### Database

You should use an external database, for example PostgreSQL, to store the persistent data.
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

⚠️ If you don't set an external database, keycloak will default to a `H2` local instance on every pod.
This means that it will not be syncronized between the different keycloak pods.

#### DNS caching

⚠️ On some cases, the Java Virtual Machine (JVM) is configured by default to cache DNS name lookups **forever**
instead of following the record's TTL. This could be problematic in cases where Keycloak should contact endpoints
that have "dynamic" DNS entries, for example AWS' RDS endpoint. In order to disable the infit cache, you need to
pass the `-Dnetworkaddress.cache.ttl=60` flag to the JVM. Where `60` is the TTL in seconds you want to use.
You can add it to the `JAVA_OPTS` environment variable.

#### Cache configuration

Set the `CACHE_OWNERS` environment variable, the default value is `1`. This value sets the number of copies that you
want to have of each keycloak's cache. If you have it set to 1, and a pods dies, you'll lose that cache contents.

#### Liveness And Readiness probes

The default value for the `liveness` and `readiness` probes is 140 seconds. It could be that your keycloak takes
more time to boot up; adjust the values accordingly to your environment.


#### Be aware of proxy headers

Make sure the ingress you are using forwards the `X-Forwarded-For` and `X-Forwarded-Proto` HTTP headers
and preserving the original `Host` HTTP header. For example, the `nginx-ingress-controller` from versions `0.22.0` and
later has this disabled by default, add this to the `data` field of the ingress `configMap` to enable it:

```yaml
use-forwarded-headers: "true"
```

## License

For license details please see [LICENSE](../../LICENSE)
