# Notes

## Quick Start

Add determined-ai

```sh
# setup namespace mlde and security
oc apply -k components/app-configs/mlde/overlays/default
```

```sh
# https://docs.determined.ai/latest/setup-cluster/k8s/install-on-kubernetes.html
# helm repo add determined-ai https://helm.determined.ai/
helm repo add mlde https://helm.determined.ai/
helm show values mlde/determined > scratch/values.yaml

helm upgrade --namespace mlde -i determined mlde/determined --values components/app-configs/mlde/base/helm-values.yaml
```

## Raw Notes

There needs to be a way to remove any `runAs[User|Group]` the following from pod definitions. `securityContext` should look like below or be undefined.

```sh
securityContext: {}
```
