<h1>
    <img src="https://github.com/sighupio/fury-distribution/blob/main/docs/assets/fury-epta-white.png?raw=true" align="left" width="90" style="margin-right: 15px"/>
    Kubernetes Fury Keycloak
</h1>

![Release](https://img.shields.io/badge/Latest%20Release-v2.0.0-blue)
![License](https://img.shields.io/github/license/sighupio/fury-kubernetes-keycloak?label=License)
![Slack](https://img.shields.io/badge/slack-@kubernetes/fury-yellow.svg?logo=slack&label=Slack)

<!-- <KFD-DOCS> -->

**Kubernetes Fury Keycloak** provides a Keycloak deployment in a High Availability cluster. It is composed by all
the `keycloak-{number}` pods in the target namespace.

If you are new to KFD please refer to the [official documentation][kfd-docs] on how to get started with KFD.

## Packages

The following packages are included in the Fury Kubernetes Keycloak katalog:

| Package                                                | Version                         | Description                                                                                 |
| ------------------------------------------------------ | ------------------------------- | ------------------------------------------------------------------------------------------- |
| [keycloak-operator](katalog/keycloak-operator)         | `21.1.1`                        | Operator to deploy and manage Keycloak and related resources |
| [keycloak-operated](katalog/keycloak-operated)         | `21.1.1`                        | High availability KeyCloak using native Kubernetes namespace based discovery. This will form a KeyCloak cluster where the members will be all the KeyCloaks pods in the same Kubernetes namespace.                         |

Click on each package to see its full documentation.

## Compatibility

| Kubernetes Version |   Compatibility    | Notes           |
| ------------------ | :----------------: | --------------- |
| `1.23.x`           | :white_check_mark: | No known issues |
| `1.24.x`           | :white_check_mark: | No known issues |
| `1.25.x`           | :white_check_mark: | No known issues |

## Usage

### Prerequisites

| Tool                        | Version   | Description                                                                                                                                                    |
| --------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [furyctl][furyctl-repo]     | `>=0.6.0` | The recommended tool to download and manage KFD modules and their packages. To learn more about `furyctl` read the [official documentation][furyctl-repo].     |
| [kustomize][kustomize-repo] | `>=3.5.0` | Packages are customized using `kustomize`. To learn how to create your customization layer with `kustomize`, please refer to the [repository][kustomize-repo]. |

### Deployment

1. List the packages in a `Furyfile.yml`

```yaml
bases:
  - name: keycloak/keycloak-operator
    version: "v2.0.0"
  - name: keycloak/keycloak-operated
    version: "v2.0.0"
```

> See `furyctl` [documentation][furyctl-repo] for additional details about `Furyfile.yml` format.

2. Execute `furyctl vendor -H` to download the packages

3. Inspect the download packages under `./vendor/katalog/keycloak`.

4. Define a `kustomization.yaml` that includes the `./vendor/katalog/keycloak` directory as resource.

```yaml
resources:
- ./vendor/katalog/keycloak/keycloak-operator
- ./vendor/katalog/keycloak/keycloak-operated
```

5. To deploy the packages to your cluster, execute:

```bash
kubectl create namespace <your-target-namespace>
kustomize build . | kubectl apply -n <your-target-namespace> -f -
```

> Note: When installing the packages, you need to ensure that the Prometheus operator is also installed.
> Otherwise, the API server will reject all ServiceMonitor resources.
> Also when installing the package you need to apply twice, in order to make the CRDs available.

### Common Customisations

#### Setup an external Database

Keycloak module ships with an internal H2 database, not suggested for a production environment.
To setup an external database you can refer to [examples/keycloak-operated-deployment](../../examples/keycloak-operated-deployment). The example uses PostgreSQL, but Keycloak also supports MariaDB, MSSQL, MySQL and Oracle.

<!-- Links -->

[kfd-repo]: https://github.com/sighupio/fury-distribution
[furyctl-repo]: https://github.com/sighupio/furyctl
[kustomize-repo]: https://github.com/kubernetes-sigs/kustomize
[kfd-docs]: https://docs.kubernetesfury.com/docs/distribution/

<!-- </KFD-DOCS> -->

<!-- <FOOTER> -->

## Contributing

Before contributing, please read first the [Contributing Guidelines](docs/CONTRIBUTING.md).

### Reporting Issues

In case you experience any problems with the module, please [open a new issue](https://github.com/sighupio/fury-kubernetes-keycloak/issues/new/choose).

## License

This module is open-source and it's released under the following [LICENSE](LICENSE)

<!-- </FOOTER> -->