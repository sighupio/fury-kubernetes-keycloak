# `keycloak-operated` Package Maintenance

This package shouldn't change a lot over time, since most of the
modifiable configuration is on the `keycloak-operator` package or
it's custom from the implementation side.

## Configuration

In `keycloak.yml` you can find a simple Keycloak operated deployment.
[Here](https://www.keycloak.org/operator/advanced-configuration) you can find
all the relevant configuration options.