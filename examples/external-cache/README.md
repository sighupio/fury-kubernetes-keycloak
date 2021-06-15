# Keycloak external cache

## Use case

This type of deployment is for when you want to run Keycloak in a cluster across multiple data centers, most typically using data center sites that are in different geographic regions. When using this mode, each data center will have its own cluster of Keycloak servers.

Eache keycloak cluster connects to an infinispan server and this infinispan server is who sends data to the other cluster via a `hotrod` connection to the others cluster's infinispan.

## External cache configuration

Keycloak will be deployed using the same configuration that for the high availability mode. With the addition of an init script and two more `JAVA_OPTS`:
```yaml
-Dremote.cache.host=infinispan-server-hotrod
-Dkeycloak.connectionsInfinispan.hotrodProtocolVersion=2.8
```

The first one sets the infinispan server address to where each keycloak will connect. The second one sets the protocol version.

Set the `-Dremote.cache.host` parameter to point to the hot-rod port of your infinispan cluster.

> ⚠️ The Infinispan cluster shall be up and running prior booting up Keycloak.

## Infinispan

Besides KeyCloak, an additional `infinispan` cluster will be deployed:

- An "infinispan-server" `StatefulSet` with `1` replica.
- An "infinispan-headless" `headless service` for the StatefulSet.
- An "infinispan-http" `Service` that exposes port `tcp/8080` to access infinispan itself.
- An "infinispan-server-hotrod" `Service` that exposes port `tcp/11222` to access infinispan hot rod protocol.
- An "infinispan" `ServiceAccount` with `list` and `get` permissions on the namespace's `pods` resource. This service account is needed in order to use the `KUBE_PING` JGroups discovery method.

In the `cloud-keycloak.xml` configuration file you can find the definition of the keycloaks caches.
