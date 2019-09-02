# Fury Kubernetes Keycloak

This repository has all the files needed to deploy RedHat's Keycloak in a High Availability cluster.

The keycloak high availabilty cluster will be form by all the `keycloak-{number}` pods in the namespace.

## Requirements

- `kustomize >= 1.0.10`
- `keycloak > 7.0` (also tested with `Keycloak 4.8.2.Final` see [notes](#considerations-for-keycloak-4.8.2.final) for this case below)
- `kubernetes >= 1.12`

## Folder structure

- **docker**: you should put your custom modifications to the official docker image here.

- **katalog**: all the kubernetes related files to deploy Keycloak on a cluster.

## Packages

- **[keycloak](#keycloak)**: high availability keycloak using native Kubernetes namespace based discovery. This will form a keycloak cluster where the members will be all the keycloaks pods in the same kubernetes namespace.
- **[keycloak-external-cache](#keycloak-external-cache)**: high availability keycloak using native kubernetes namespace discovery and an external infinispan cache cluster for multisite deployments.
- **[infinispan](#infinispan)**: an Infinispan cache cluster deployment, to be used by `keycloak-external-cache`.

# Keycloak

## Configuration

Keycloak will be deployed with the following configuration:

- A "keycloak" `StatefulSet` with `1` replica.
- A "keycloak-discovery" `headless service` for the StatefulSet.
- A "keycloak-http" `Service` that exposes port `tcp/8080` to access keycloak itself.
- A "keycloak" `ServiceAccount` with `list` and `get` permissions on the namespace's `pods` resource. This service account is needed in order to use the `KUBE_PING` JGroups discovery method.
- Default credentials to access the admin console:
  - Username: `admin`
  - Password: `admin`

  You probably want to change them, make an overlay of the following environment variables:

```yaml
          - name: KEYCLOAK_USER
            value: "admin"
          - name: KEYCLOAK_PASSWORD
            value: "admin"
```

## Why a StatefulSet?

Beacuse we want to use the pod's name as the value for `jboss.node.name` and `jboss.tx.node.id`, and both have a hard-limit of 27 characters. A podname with the deployment hash has more than 27 characters, so we use an StatefulSet insted to control the name's length.

## Recommendations

- Set the `replicas` count to your desired number using an overlay.

- It is strongly recommended to use sticky sessions in your ingress definition for keycloak. The `cookie` to use is `AUTH_SESSION_ID`. See example below:

```yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: "external"
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "AUTH_SESSION_ID"
  name: keycloak-external
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

- You should use an external database, for example PostgreSQL, to store the persistent data. You can configure Keycloak to use the database setting the following environment variables:

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

> ⚠️ If you not set an external database, keycloak will default to a `H2` local instance on every pod. This means that it will not be syncronized between the different keycloak pods.

- Set the `CACHE_OWNERS` environment variable, the default value is `1`. This value sets the amount of copies that you want to have of each keycloak's cache. If you have it set to 1, and a pods dies, you'll lose that cache contents.

- The default value for the `liveness` and `readiness` probes is 140 seconds. It could be that your keycloak takes more time to boot up, adjust the values accordingly to your environment.

- Make sure the ingress you are using forwards the `X-Forwarded-For` and `X-Forwarded-Proto` HTTP headers and preserving the original `Host` HTTP header. For example, the `nginx-ingress-controller` from versions `0.22.0` and later has this disabled by default, add this to the `data` field of the ingress `configMap` to enable it:

```yaml
use-forwarded-headers: "true"
```

## Considerations for Keycloak 4.8.2.Final

If you need to deploy keycloak version `4.8.2.Final` or older, there are a few caveats to have in mind.

### Clustering

This version doesn't have native support for running on kubernetes, there's a problem with `multicast` that you have to consider.
If you are going to deploy more than one _keycloak cluser_ on the same _kubernetes cluster_, check that the different keycloak clusters don't see each other. For example, if the 2 kubernetes clusters are on the same AWS VPC but differente namespaces, the keycloak from the different namespaces will join each other. This is beacause `Keycloak 4.8.2.Final` uses **multicast ping** to discover other nodes even though jgroups is setup to use other method like `KUBE_PING`. To solve this problem you need to override the `JAVA_OPTS` environment variable adding the following snippet:

```yaml
              -Djboss.default.multicast.address=230.0.0.5
              -Djboss.modcluster.multicast.address:224.0.1.106
```

So the patch will look like something like this:
```yaml
          - name: JAVA_OPTS
            value: >-
              -server
              -Djava.net.preferIPv4Stack=true
              -Djava.awt.headless=true
              -Djboss.default.jgroups.stack=kubernetes
              -Djboss.node.name=staging-$(POD_NAME)
              -Djboss.tx.node.id=staging-$(POD_NAME)
              -Djboss.site.name=$(KUBERNETES_NAMESPACE)
              -Djboss.default.multicast.address=230.0.0.5
              -Djboss.modcluster.multicast.address:224.0.1.106
```

> ⚠️ Have in mind that `kustomize` doesn't support expanding environment variables with `$(VARNAME)` when the variable has been defined in another `yaml` file. So you need to redefine locally every `$(VAR)` you want to expand, like `$(POD_NAME)` and `$(KUBERNETES_NAMESPACE)` in the previous example.

> The `JAVA_OPTS` environment variable has to be set *in every namespace*, this is because at the moment of writing this module, the `Wildfly` application server that keycloak uses doesn't support extending this environment variable with something like `EXT_JAVA_OPTS`. So, in order to add specific variables to each namespace, we need to repeat ourselves. This can be improved though.


### Database configuration

The database configurations parameters are different, this are the ones to use for keycloak 4.8.2.Final:

```yaml
          - name: DB_VENDOR
            value: "postgres"
          - name: POSTGRES_ADDR
            value: "postgres"
          - name: POSTGRES_PORT
            value: "5432"
          - name: POSTGRES_DB
            value: "keycloak"
          - name: POSTGRES_USER
            value: "keycloak"
          - name: POSTGRES_PASSWORD
            value: "password"
```

### JBOSS Startup CLIs

If you need to use Keycloak version `4.8.2.Final` or *older* you need to backport the startup scripts functionality. We have already done it, use the `Dockerfile` that is in the `docker` folder and set the version you want to start from to add the startup scripts feature, then build your image and use it for the StatefulSet.

# Keycloak external cache

## Use case

This type of deployment is for when you want to run Keycloak in a cluster across multiple data centers, most typically using data center sites that are in different geographic regions. When using this mode, each data center will have its own cluster of Keycloak servers. 

Eache keycloak cluster connects to an infinispan server and this infinispan server is who sends data to the other cluster via a `hotrod` connection to the others cluster's infinispan.


## Configuration

Keycloak will be deployed using the same configuration that for the high availability mode. With the addition of an init script and two more `JAVA_OPTS`:
```yaml
-Dremote.cache.host=infinispan-server-hotrod
-Dkeycloak.connectionsInfinispan.hotrodProtocolVersion=2.8
```

The first one sets the infinispan server address to where each keycloak will connect. The second one sets the protocol version.

Set the `-Dremote.cache.host` parameter to point to the hot-rod port of your infinispan cluster.

> ⚠️ The Infinispan cluster shall be up and running prior booting up Keycloak.

## Infinispan
Besides Keycloak, an additional `infinispan` cluster will be deployed:
- An "infinispan-server" `StatefulSet` with `1` replica.
- An "infinispan-headless" `headless service` for the StatefulSet.
- An "infinispan-http" `Service` that exposes port `tcp/8080` to access infinispan itself.
- An "infinispan-server-hotrod" `Service` that exposes port `tcp/11222` to access infinispan hot rod protocol.
- An "infinispan" `ServiceAccount` with `list` and `get` permissions on the namespace's `pods` resource. This service account is needed in order to use the `KUBE_PING` JGroups discovery method.

In the `cloud-keycloak.xml` configuration file you can find the definition of the keycloaks caches.

