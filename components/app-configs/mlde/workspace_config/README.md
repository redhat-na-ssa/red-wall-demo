# Example manifests for creating MLDE Workspace resources in Openshift

This directory intends to make a simple starting point to generate all the resources for attaching a service account for MLDE workloads, while respecting OpenShift UID rules. This is due to both products solving for running non-root containers, using different strategies.

## Description

In order to respect both product's methods for forcing non-root containers, the following logic is implemented:

* MLDE Workloads (i.e. Notebooks and Experiments) will be forced to use a Service Account, `mlde-worker`
  * The `mlde-worker` is permitted to use the OpenShift `nonroot` SCC policy. This means any UID is allowed, as long as it is not a root user.
* For any workload in the same namespace that __does not specify a ServiceAccount__ to use, it will defer to `default`
  * The `default` ServiceAccount will respect OpenShift's `restricted` SCC
* For more details, reference <https://www.redhat.com/en/blog/managing-sccs-in-openshift>

## Get Started

1. Assuming you are running from this directory
2. Copy and modify the service-principal-template to match the Service Principal being used for the Workspace.

```sh
cp kubernetes.service-principal-template.json kubernetes.service-principal.json
```

3. Modify `kustomization.yaml` to match the namespace that should be used. This needs to repeat for each namespace.
    * Note: In MLDE, we generally advise keeping 1 namespace to 1 workspace
4. Run kustomize by using

```
kubectl apply -k .
```

5. In the MLDE workspace, create a new template, using the contents of `mlde-task-template.yaml`
