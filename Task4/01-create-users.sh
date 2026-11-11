#!/usr/bin/env bash
# Task4, шаг 1. Создание пользователей кластера.
# Пользователь в Kubernetes - subject клиентского сертификата: CN - имя, O - группа.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="${SCRIPT_DIR}/manifests"
WORKDIR="${WORKDIR:-${SCRIPT_DIR}/users}"
CLUSTER_NAME="${CLUSTER_NAME:-$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')}"

# логин | группа (O)
USERS=(
  "anna.viewer|propdev:viewers"
  "ivan.devops.gku|propdev:operators:gku"
  "petr.dev.sales|propdev:developers:sales"
  "sergey.security|propdev:security"
  "olga.platform|propdev:platform"
)

log() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$1"; }

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "ОШИБКА: нет доступа к кластеру" >&2
  exit 1
fi

CA_DATA="$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' || true)"
if [[ -z "${CA_DATA}" ]]; then
  CA_PATH="$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority}')"
  CA_DATA="$(base64 -w0 "${CA_PATH}")"
fi
API_SERVER="$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}')"

mkdir -p "${WORKDIR}"
chmod 700 "${WORKDIR}"

log "Namespace и сервисные аккаунты"
kubectl apply -f "${MANIFESTS}/00-namespaces.yaml"
kubectl apply -f "${MANIFESTS}/01-service-accounts.yaml"

for entry in "${USERS[@]}"; do
  IFS='|' read -r user group <<< "${entry}"
  log "Пользователь ${user}, группа ${group}"

  openssl genrsa -out "${WORKDIR}/${user}.key" 2048 2>/dev/null
  openssl req -new -key "${WORKDIR}/${user}.key" \
    -out "${WORKDIR}/${user}.csr" -subj "/CN=${user}/O=${group}"

  kubectl delete csr "${user}" --ignore-not-found >/dev/null

  kubectl apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${user}
spec:
  request: $(base64 -w0 "${WORKDIR}/${user}.csr")
  signerName: kubernetes.io/kube-apiserver-client
  usages:
    - client auth
EOF

  kubectl certificate approve "${user}"

  crt=""
  for _ in $(seq 1 15); do
    crt="$(kubectl get csr "${user}" -o jsonpath='{.status.certificate}')"
    [[ -n "${crt}" ]] && break
    sleep 1
  done
  if [[ -z "${crt}" ]]; then
    echo "ОШИБКА: сертификат для ${user} не выдан" >&2
    exit 1
  fi
  echo "${crt}" | base64 -d > "${WORKDIR}/${user}.crt"

  kubeconfig="${WORKDIR}/${user}.kubeconfig"
  kubectl --kubeconfig="${kubeconfig}" config set-cluster "${CLUSTER_NAME}" \
    --server="${API_SERVER}" --embed-certs=true \
    --certificate-authority=<(echo "${CA_DATA}" | base64 -d) >/dev/null
  kubectl --kubeconfig="${kubeconfig}" config set-credentials "${user}" \
    --client-certificate="${WORKDIR}/${user}.crt" \
    --client-key="${WORKDIR}/${user}.key" --embed-certs=true >/dev/null
  kubectl --kubeconfig="${kubeconfig}" config set-context "${user}" \
    --cluster="${CLUSTER_NAME}" --user="${user}" >/dev/null
  kubectl --kubeconfig="${kubeconfig}" config use-context "${user}" >/dev/null

  echo "  kubeconfig: ${kubeconfig}"
done

log "Создано пользователей: ${#USERS[@]}"
kubectl get csr -o custom-columns=USER:.metadata.name,CONDITION:.status.conditions[0].type
