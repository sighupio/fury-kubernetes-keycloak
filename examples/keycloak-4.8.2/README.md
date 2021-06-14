# KeyCloak 4.8.2

## Considerations

While deploying keycloak version `4.8.2.Final` or older, there are a few caveats to have in mind.

### Clustering

This version doesn't have native support for running on Kubernetes, there's a problem with `multicast`
that you have to consider.
If you are going to deploy more than one _keycloak cluser_ on the same _kubernetes cluster_, check that the different
KeyCloak clusters don't see each other. For example, if the two Kubernetes clusters are on the same AWS VPC but differente namespaces, the keycloak from the different namespaces will join each other. This is beacause `Keycloak 4.8.2.Final` uses **multicast ping** to discover other nodes even though jgroups is setup to use other method like `KUBE_PING`. To solve this problem you need to override the `JAVA_OPTS` environment variable adding the following snippet:

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
