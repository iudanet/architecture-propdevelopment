#!/usr/bin/env bash
# Task4, шаг 2. Создание ролей по таблице roles-table.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="${SCRIPT_DIR}/manifests"

log() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$1"; }

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "ОШИБКА: нет доступа к кластеру" >&2
  exit 1
fi

log "Роли уровня кластера"
kubectl apply -f "${MANIFESTS}/10-clusterroles.yaml"

log "Роль доступа к секретам по namespace"
kubectl apply -f "${MANIFESTS}/11-secret-reader-roles.yaml"

log "Созданные роли"
kubectl get clusterrole -l propdev.ru/role-kind \
  -o custom-columns='ROLE:.metadata.name,KIND:.metadata.labels.propdev\.ru/role-kind'
echo
kubectl get role -A -l propdev.ru/role-kind \
  -o custom-columns=NAMESPACE:.metadata.namespace,ROLE:.metadata.name

log "Контроль: доступ к секретам только у secret-reader"
for role in cluster-viewer namespace-viewer namespace-operator ci-deployer security-auditor; do
  if kubectl get clusterrole "${role}" -o jsonpath='{.rules[*].resources}' | grep -qw secrets; then
    echo "  ОШИБКА   ${role} содержит secrets"
  else
    echo "  OK       ${role} без secrets"
  fi
done
