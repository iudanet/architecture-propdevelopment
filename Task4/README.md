# Task4 - Ролевой доступ к кластеру Kubernetes

| Файл | Содержание |
|---|---|
| [`roles-table.md`](./roles-table.md) | Таблица ролей: роль, полномочия, группы пользователей |
| [`01-create-users.sh`](./01-create-users.sh) | Создание пользователей |
| [`02-create-roles.sh`](./02-create-roles.sh) | Создание ролей |
| [`03-bind-roles.sh`](./03-bind-roles.sh) | Связывание пользователей с ролями, проверка прав |
| [`manifests/`](./manifests) | Манифесты, которые применяют скрипты |

## Манифесты

| Файл | Объекты |
|---|---|
| `00-namespaces.yaml` | Namespace доменов: sales, gku, finance, data, integration, security |
| `01-service-accounts.yaml` | ServiceAccount ci-deployer в namespace доменов |
| `10-clusterroles.yaml` | ClusterRole: cluster-viewer, namespace-viewer, namespace-operator, ci-deployer, security-auditor, platform-admin |
| `11-secret-reader-roles.yaml` | Role secret-reader в каждом namespace |
| `20-clusterrolebindings.yaml` | ClusterRoleBinding для групп viewers, platform, security |
| `21-rolebindings-domains.yaml` | RoleBinding в namespace доменов: разработчики, эксплуатация, CI/CD |
| `22-rolebindings-privileged.yaml` | RoleBinding доступа к секретам, включая временный (JIT) |

## Порядок запуска

```bash
minikube start
./01-create-users.sh
./02-create-roles.sh
./03-bind-roles.sh
```

Роли и привязки заданы манифестами в `manifests/`, скрипты их применяют.
Каталог `users/` с закрытыми ключами в репозиторий не попадает.
