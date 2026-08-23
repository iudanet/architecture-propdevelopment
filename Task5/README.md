# Task5 - Управление трафиком внутри кластера Kubernetes

| Файл | Содержание |
|---|---|
| [`non-admin-api-allow.yaml`](./non-admin-api-allow.yaml) | Сетевые политики разделения трафика UI и API |
| [`isolated-service-deny.yaml`](./isolated-service-deny.yaml) | Изоляция нового сервиса от остальных подов |
| [`01-deploy-services.sh`](./01-deploy-services.sh) | Развёртывание сервисов с метками-ролями |
| [`02-apply-and-verify.sh`](./02-apply-and-verify.sh) | Применение политик и проверка трафика |

## Запуск

```bash
minikube start --cni=calico
./01-deploy-services.sh
./02-apply-and-verify.sh
```

Calico обязателен: без CNI с поддержкой NetworkPolicy политики не действуют.

## Сервисы и метки

| Сервис | Метка role |
|---|---|
| front-end-app | `front-end` |
| back-end-api-app | `back-end-api` |
| admin-front-end-app | `admin-front-end` |
| admin-back-end-api-app | `admin-back-end-api` |
| isolated-service-app | `isolated-service` |

## Политики

| Политика | Действие |
|---|---|
| `default-deny-all` | Запрет входящего и исходящего трафика для всех подов namespace |
| `allow-dns-egress` | Разрешение обращений к kube-dns: без него не разрешается имя сервиса |
| `back-end-api-allow-front-end` | В `back-end-api` входит трафик только от `front-end` |
| `front-end-allow-back-end-api` | Из `front-end` исходит трафик только в `back-end-api` |
| `admin-back-end-api-allow-admin-front-end` | В `admin-back-end-api` входит трафик только от `admin-front-end` |
| `admin-front-end-allow-admin-back-end-api` | Из `admin-front-end` исходит трафик только в `admin-back-end-api` |
| `front-end-allow-back-end-api-ingress` | В `front-end` входит трафик от `back-end-api` |
| `back-end-api-allow-front-end-egress` | Из `back-end-api` исходит трафик в `front-end` |
| `admin-front-end-allow-admin-back-end-api-ingress` | В `admin-front-end` входит трафик от `admin-back-end-api` |
| `admin-back-end-api-allow-admin-front-end-egress` | Из `admin-back-end-api` исходит трафик в `admin-front-end` |
| `isolated-service-deny-ingress` | В `isolated-service` не входит трафик ни от одного пода |
| `isolated-service-egress-dns-only` | Из `isolated-service` разрешён только DNS |

## Матрица трафика

| Источник \ Получатель | front-end | back-end-api | admin-front-end | admin-back-end-api | isolated-service |
|---|---|---|---|---|---|
| front-end | - | разрешено | запрещено | запрещено | запрещено |
| back-end-api | разрешено | - | запрещено | запрещено | запрещено |
| admin-front-end | запрещено | запрещено | - | разрешено | запрещено |
| admin-back-end-api | запрещено | запрещено | разрешено | - | запрещено |
| isolated-service | запрещено | запрещено | запрещено | запрещено | - |
