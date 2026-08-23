#!/usr/bin/env bash
# Task5, шаг 2. Применение сетевых политик и проверка трафика.
# Проверка выполняется временным alpine-подом: ему присваивается метка role
# проверяемого источника, поэтому политики применяются к нему так же,
# как к реальному сервису. Образ nginx не содержит клиента HTTP.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS="${NS:-netpol-demo}"

log() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$1"; }

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "ОШИБКА: нет доступа к кластеру" >&2
  exit 1
fi

log "Применение политик"
kubectl -n "${NS}" apply -f "${SCRIPT_DIR}/non-admin-api-allow.yaml"
kubectl -n "${NS}" apply -f "${SCRIPT_DIR}/isolated-service-deny.yaml"
kubectl -n "${NS}" get networkpolicy

failed=0
probe() {
  local role="$1" target="$2"
  local pod="probe-${RANDOM}"
  if kubectl -n "${NS}" run "${pod}" --image=alpine:3.20 --labels "role=${role}" \
       --restart=Never --rm -i --pod-running-timeout=90s --quiet -- \
       wget -qO- --timeout=3 "http://${target}" >/dev/null 2>&1; then
    echo allow
  else
    echo deny
  fi
}

check() {
  local expect="$1" role="$2" target="$3" desc="$4"
  local got
  got="$(probe "${role}" "${target}")"
  if [[ "${got}" == "${expect}" ]]; then
    printf '  OK       %s: %s\n' "${desc}" "${got}"
  else
    printf '  ОШИБКА   %s: ожидалось %s, получено %s\n' "${desc}" "${expect}" "${got}"
    failed=$((failed + 1))
  fi
}

log "Проверка трафика"
check allow front-end          back-end-api-app       "front-end -> back-end-api"
check allow admin-front-end    admin-back-end-api-app "admin-front-end -> admin-back-end-api"
check deny  front-end          admin-back-end-api-app "front-end -> admin-back-end-api"
check deny  admin-front-end    back-end-api-app       "admin-front-end -> back-end-api"
check allow back-end-api       front-end-app          "back-end-api -> front-end (обратное)"
check allow admin-back-end-api admin-front-end-app    "admin-back-end-api -> admin-front-end (обратное)"
check deny  back-end-api       admin-back-end-api-app "back-end-api -> admin-back-end-api"
check deny  back-end-api       admin-front-end-app    "back-end-api -> admin-front-end"
check deny  front-end          isolated-service-app   "front-end -> isolated-service"
check deny  back-end-api       isolated-service-app   "back-end-api -> isolated-service"
check deny  isolated-service   back-end-api-app       "isolated-service -> back-end-api"

echo
if [[ ${failed} -eq 0 ]]; then
  echo "Все проверки пройдены."
else
  echo "Проверок с расхождением: ${failed}" >&2
  exit 1
fi
