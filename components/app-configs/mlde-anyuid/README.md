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

# helm show values mlde/determined > scratch/values.yaml

# run helm install w/ values
helm upgrade --namespace mlde -i determined mlde/determined --values components/app-configs/mlde/base/helm-values.yaml
```

## Raw Notes

There needs to be a way to remove any `runAs[User|Group]` from pod definitions. `securityContext` should look like below or be undefined on `job` or `pod` definitions

```sh
securityContext: {}
```

Template Test (does not work)

```yaml
# see https://docs.determined.ai/latest/setup-cluster/k8s/custom-pod-specs.html
environment:
  image:
    cpu: docker.io/determinedai/pytorch-ngc:0.35.0
    cuda: docker.io/determinedai/pytorch-ngc:0.35.0
  pod_spec:
    apiVersion: v1
    kind: Pod
    spec:
      initContainers:
        - name: determined-init-container
          securityContext: {}
      containers:
        - name: determined-container
          securityContext: {}
```
