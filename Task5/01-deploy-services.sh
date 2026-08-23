#!/usr/bin/env bash
# Task5, шаг 1. Развёртывание сервисов с метками-ролями.

set -euo pipefail

NS="${NS:-netpol-demo}"

log() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$1"; }

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "ОШИБКА: нет доступа к кластеру" >&2
  exit 1
fi

log "Namespace ${NS}"
kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

# имя пода | метка role
SERVICES=(
  "front-end-app|front-end"
  "back-end-api-app|back-end-api"
  "admin-front-end-app|admin-front-end"
  "admin-back-end-api-app|admin-back-end-api"
  "isolated-service-app|isolated-service"
)

log "Сервисы с метками"
for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name role <<< "${entry}"
  if kubectl -n "${NS}" get pod "${name}" >/dev/null 2>&1; then
    echo "  ${name} (role=${role}) уже существует"
    continue
  fi
  kubectl -n "${NS}" run "${name}" --image=nginx:alpine \
    --labels "role=${role}" --expose --port 80
done

log "Ожидание готовности подов"
kubectl -n "${NS}" wait --for=condition=Ready pod --all --timeout=120s

log "Развёрнуто"
kubectl -n "${NS}" get pods --show-labels
echo
kubectl -n "${NS}" get svc
