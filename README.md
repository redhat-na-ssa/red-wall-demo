# Demo OpenShift Config

This repo is used to track the configuration for an OpenShift cluster via GitOps.

## Quick Start

Run ONCE commands - for initial setup

```sh
# initialize the secret for htpasswd auth
oc apply -f components/cluster-configs/login/overlays/htpasswd/htpasswd-secret.yaml

# setup basic cluster groups
oc apply -k components/cluster-configs/rbac/overlays/default

# disable self provisioner
oc apply -k components/cluster-configs/rbac/overlays/no-self-provisioner
```

Apply cluster config

```sh
oc apply -k bootstrap/
```

Add users to htpasswd

```sh
. scripts/functions.sh

ocp_setup_user < username > < password - optional>
```

Annotate default storage class

```yaml
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
```

Label worker nodes with lvm for storage use

```sh
oc label nodes -l 'node-role.kubernetes.io/worker=' 'node-role.kubernetes.io/lvm='
```

## Links
