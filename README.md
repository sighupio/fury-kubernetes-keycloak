# Fury Kubernetes KeyCloak

This repository has all the files needed to deploy KeyCloak in a High Availability cluster. It is composed by all
the `keycloak-{number}` pods in the namespace.

## KeyCloak Packages

The following packages are included in the Fury Kubernetes KeyCloak Katalog.

- **[keycloak](#keycloak)**: high availability KeyCloak using native Kubernetes namespace based discovery.
This will form a KeyCloak cluster where the members will be all the KeyCloaks pods in the same Kubernetes namespace.
Version: **13.0.1**.

## Requirements

All packages in this repository have the following dependencies, for package
specific dependencies, please visit the single package's documentation:

- [Kubernetes](https://kubernetes.io) >= `v1.18.0`
- [Furyctl](https://github.com/sighupio/furyctl) package manager to download
  Fury packages >= [`v0.2.2`](https://github.com/sighupio/furyctl/releases/tag/v0.2.2)
- [Kustomize](https://github.com/kubernetes-sigs/kustomize) >= `v3.10.0`

## Compatibility

| Module Version / Kubernetes Version |       1.18.X       |       1.19.X       |       1.20.X       |  1.21.X   |
| ----------------------------------- | :----------------: | :----------------: | :----------------: | :-------: |
| v1.0.0                              |                    |                    |                    |           |
| v1.0.1                              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :warning: |
| v1.1.0                              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :warning: |

- :white_check_mark: Compatible
- :warning: Has issues
- :x: Incompatible

## Metrics

The current package provides access to the metrics exposed by Keycloak, enabled using the env var `KEYCLOAK_STATISTICS=all`. Also, a ServiceMonitor is included, to be attached to [Prometheus Operator](https://github.com/sighupio/fury-kubernetes-monitoring/tree/master/katalog/prometheus-operator).

## Examples

To see examples on how to customize Fury Kubernetes KeyCloak packages, please
go to [examples](examples) directory.

- [`h2-tests`](examples/h2-tests): Use only this option to test KeyCloak. It is used in the E2E tests.
- [`external-cache`](examples/external-cache): Use this setup to run KeyCloak in a cluster across multiple data
centers.
- [`keycloak-4.8.2`](examples/keycloak-4.8.2): You should put your custom modifications to the official docker image
here.

## License

For license details, please see [LICENSE](LICENSE)
