#!/bin/bash

which oc >/dev/null && alias kubectl=oc

# shellcheck disable=SC2120
genpass(){
    < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"${1:-32}"
}

which htpasswd || return
which oc || return
[ -e scratch ] || mkdir -p scratch

HTPASSWD_FILE=scratch/htpasswd
KUBECONFIG_FILE=scratch/kubeconfig
OCP_ADMIN_GROUP=cluster-readers

htpasswd_add_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}

  echo "
    USERNAME: ${USER}
    PASSWORD: ${PASS}

    FILE: ${HTPASSWD_FILE}
  "

  touch "${HTPASSWD_FILE}"
  htpasswd -bB -C 10 "${HTPASSWD_FILE}" "${USER}" "${PASS}"
}

htpasswd_sort_file(){
  sort -u "${HTPASSWD_FILE}" > tmp
  mv tmp "${HTPASSWD_FILE}"
}

htpasswd_get_file(){
  oc -n openshift-config \
    extract secret/oauth-htpasswd \
    --keys=htpasswd \
    --to=scratch
}

htpasswd_set_file(){
  oc -n openshift-config \
    set data secret/oauth-htpasswd \
    --from-file=htpasswd="${HTPASSWD_FILE}"
}

htpasswd_set_ocp_admin(){
  USER=${1:-admin}
  OCP_ADMIN_GROUP=${2:-cluster-readers}
  
  oc adm groups add-users \
  "${OCP_ADMIN_GROUP}" "${USER}"
}

ocp_setup_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}
  
  htpasswd_add_user "${USER}" "${PASS}"
  htpasswd_set_ocp_admin "${USER}" cluster-readers

  echo "
    run: htpasswd_set_file
  "
}

which age || return

htpasswd_decrypt_file(){
  age --decrypt \
    -i ~/.ssh/id_ed25519 \
    -i ~/.ssh/id_rsa \
    -o "${HTPASSWD_FILE}" \
    htpasswd.age
}

htpasswd_encrypt_file(){
  age --encrypt --armor \
    -R authorized_keys \
    -o htpasswd.age \
    "${HTPASSWD_FILE}"
}

kubeconfig_decrypt_file(){
  age --decrypt \
    -i ~/.ssh/id_ed25519 \
    -i ~/.ssh/id_rsa \
    -o "${KUBECONFIG_FILE}" \
    kubeconfig.age
}

kubeconfig_encrypt_file(){
  age --encrypt --armor \
    -R authorized_keys \
    -o kubeconfig.age \
    "${KUBECONFIG_FILE}"
}

ocp_label_amd_nodes(){
  oc label node \
    -l feature.node.kubernetes.io/pci-1002.present \
    node-role.kubernetes.io/amd-gpu=
}

# shellcheck disable=SC2016
amd_gpu_get_pods(){
  oc get pod -A \
    -ogo-template='
    {{- range .items }}
      {{- $name := .metadata.name }}
      {{- $ns := .metadata.namespace }}
      {{- range $container := .spec.containers }}
        {{- if and (and (index $container "resources") (index $container.resources "requests")) (index $container.resources.requests "amd.com/gpu") }}
          {{- $ns }}/{{ $name }}{{ "\n" }}
        {{- end }}
      {{- end }}
    {{- end }}'
}

k8s_api_start_proxy(){
  echo "k8s api proxy: starting..."
  kubectl proxy -p 8001 &
  API_PROXY_PID=$!
  sleep 3
}

k8s_delete_extended_resource_on_all_nodes(){
  RESOURCE_NAME=${1:-amd.com~1gpu}

  echo "Attempting to delete extended resource ${RESOURCE_NAME}..."

  k8s_api_start_proxy

  for node in $(kubectl get nodes -o name | sed 's/node.//')
  do
    echo "modifying: ${node}"
    curl "http://localhost:8001/api/v1/nodes/${node}/status" \
      --header "Content-Type: application/json-patch+json" \
      --request PATCH \
      --data '[{"op": "remove", "path": "/status/capacity/'"${RESOURCE_NAME}"'"}]' \
      --no-fail
      
  done

  echo "k8s api proxy: stopping..."
  kill "${API_PROXY_PID}"
}
