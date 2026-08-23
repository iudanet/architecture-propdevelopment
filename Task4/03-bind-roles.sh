#!/usr/bin/env bash
# Task4, шаг 3. Привязка групп и сервисных аккаунтов к ролям.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="${SCRIPT_DIR}/manifests"

log() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$1"; }

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "ОШИБКА: нет доступа к кластеру" >&2
  exit 1
fi

log "Привязки уровня кластера"
kubectl apply -f "${MANIFESTS}/20-clusterrolebindings.yaml"

log "Привязки по доменам: разработчики, эксплуатация, CI/CD"
kubectl apply -f "${MANIFESTS}/21-rolebindings-domains.yaml"

log "Привилегированный доступ к секретам"
kubectl apply -f "${MANIFESTS}/22-rolebindings-privileged.yaml"

log "Созданные привязки"
kubectl get clusterrolebinding -l propdev.ru/binding \
  -o custom-columns=BINDING:.metadata.name,ROLE:.roleRef.name,SUBJECT:.subjects[0].name
echo
kubectl get rolebinding -A -l propdev.ru/binding \
  -o custom-columns=NAMESPACE:.metadata.namespace,BINDING:.metadata.name,ROLE:.roleRef.name,SUBJECT:.subjects[0].name

log "Проверка фактических прав"
failed=0
check() {
  local expect="$1" desc="$2"; shift 2
  local got
  got="$(kubectl auth can-i "$@" 2>/dev/null || true)"
  got="${got%%$'\n'*}"
  if [[ "${got}" == "${expect}" ]]; then
    printf '  OK       %s: %s\n' "${desc}" "${got}"
  else
    printf '  ОШИБКА   %s: ожидалось %s, получено %s\n' "${desc}" "${expect}" "${got:-пусто}"
    failed=$((failed + 1))
  fi
}

check yes "разработчик sales: просмотр подов в sales" \
  get pods -n sales --as=petr.dev.sales --as-group=propdev:developers:sales
check no  "разработчик sales: чтение секретов в sales" \
  get secrets -n sales --as=petr.dev.sales --as-group=propdev:developers:sales
check no  "разработчик sales: просмотр подов в gku (чужой домен)" \
  get pods -n gku --as=petr.dev.sales --as-group=propdev:developers:sales
check yes "DevOps gku: изменение deployment в gku" \
  update deployments -n gku --as=ivan.devops.gku --as-group=propdev:operators:gku
check no  "DevOps gku: чтение секретов в gku (нужен JIT-доступ)" \
  get secrets -n gku --as=ivan.devops.gku --as-group=propdev:operators:gku
check no  "DevOps gku: изменение deployment в finance (чужой домен)" \
  update deployments -n finance --as=ivan.devops.gku --as-group=propdev:operators:gku
check yes "ведущий DevOps gku: чтение секретов в gku (JIT)" \
  get secrets -n gku --as=lead.gku --as-group=propdev:operators:gku:lead
check yes "специалист по ИБ: чтение секретов в finance" \
  get secrets -n finance --as=sergey.security --as-group=propdev:security
check yes "специалист по ИБ: просмотр rolebindings" \
  list rolebindings -n gku --as=sergey.security --as-group=propdev:security
check yes "аналитик: просмотр подов во всём кластере" \
  get pods --all-namespaces --as=anna.viewer --as-group=propdev:viewers
check no  "аналитик: изменение deployment" \
  update deployments -n sales --as=anna.viewer --as-group=propdev:viewers
check no  "аналитик: чтение секретов" \
  get secrets -n sales --as=anna.viewer --as-group=propdev:viewers
check yes "платформенная команда: создание namespace" \
  create namespaces --as=olga.platform --as-group=propdev:platform
check yes "CI/CD sales: обновление deployment" \
  update deployments -n sales --as=system:serviceaccount:sales:ci-deployer
check no  "CI/CD sales: удаление deployment" \
  delete deployments -n sales --as=system:serviceaccount:sales:ci-deployer
check no  "CI/CD sales: чтение секретов" \
  get secrets -n sales --as=system:serviceaccount:sales:ci-deployer

echo
if [[ ${failed} -eq 0 ]]; then
  echo "Все проверки прав пройдены."
else
  echo "Проверок с расхождением: ${failed}" >&2
  exit 1
fi
