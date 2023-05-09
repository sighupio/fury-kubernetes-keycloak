# Keycloak

Keycloak is an open source software product to allow single sign-on with Identity and Access Management aimed at
modern applications and services.

## Configuration

Keycloak ships with the following options:

- A "keycloak" `StatefulSet` with `1` replica.
- A "keycloak-discovery" `headless service` for the StatefulSet.
- A "keycloak" `Service` exposing port `tcp/8080` to access Keycloak itself.
- Default credentials to access the admin console:
  - Username: `admin`
  - Password: you can obtain it using `kubectl get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 --decode`

### Custom Docker image

The Docker image used in this package has been built from [Fury images](https://github.com/sighupio/fury-distribution-container-image-sync/blob/main/modules/keycloak/images.yml) installing the [Keycloak Metrics SPI](https://github.com/aerogear/keycloak-metrics-spi), so Keycloak metrics about internal events are exposed to `/realms/master/metrics`.

### Metrics

The current package provides access to the core metrics exposed to `/metrics` by Keycloak, enabled using the env var `KC_METRICS_ENABLED=true`. Also, a ServiceMonitor is included, to be attached to [Prometheus Operator](https://github.com/sighupio/fury-kubernetes-monitoring/tree/master/katalog/prometheus-operator).

### Recommendations

#### Replicas

Set the `replicas` count to your desired number using an overlay.

#### Database

You should use an external database, for example PostgreSQL, to store the persistent data.
You can configure Keycloak patching the Keycloak resource, for example:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-db-secret
stringData:
  username: postgres_user
  password: postgres_password
---
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
spec:
  db:
    vendor: postgres
    host: postgres-db
    usernameSecret:
      name: keycloak-db-secret
      key: username
    passwordSecret:
      name: keycloak-db-secret
      key: password
```