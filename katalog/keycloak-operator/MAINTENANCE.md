# `keycloak-operator` Package Maintenance

To prepare a new release of this package:

1. Get the current upstream release and download the resources

Visit https://github.com/keycloak/keycloak-k8s-resources/tags

```bash
export KEYCLOAK_OPERATOR_UPSTREAM_RELEASE=21.1.1
wget -O crds/keycloaks.k8s.keycloak.org-v1.yml https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${KEYCLOAK_OPERATOR_UPSTREAM_RELEASE}/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
wget -O crds/keycloakrealmimports.k8s.keycloak.org-v1.yml https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${KEYCLOAK_OPERATOR_UPSTREAM_RELEASE}/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml

wget -O keycloak-operator.yml https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${KEYCLOAK_OPERATOR_UPSTREAM_RELEASE}/kubernetes/kubernetes.yml

```

2. Check the differences introduced by pulling the upstream release and add the needed patches in `kustomization.yaml`

Also pay attention to the files already present in `patches` folder, since some versions or configurations may need to be changed.

3. Sync the new images to our registry in the [`keycloak` images.yaml file fury-distribution-container-image-sync repository](https://github.com/sighupio/fury-distribution-container-image-sync/blob/main/modules/keycloak/images.yml).

4. Update the `kustomization.yaml` file with the new image.
