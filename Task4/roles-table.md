# Ролевая модель доступа к кластеру Kubernetes

Разграничение построено по организационной структуре PropDevelopment: четыре домена
(продажи, ЖКУ, финансы, дата), в каждом - продуктовые команды из функциональной
и операционной части.

## Namespace по доменам

| Namespace | Домен | Сервисы |
|---|---|---|
| `sales` | Группа сервисов для клиентов | Витрина продаж, client-mart-app, client-mart-estate-app, client-tour-app, client-crm-app |
| `gku` | Группа сервисов ЖКУ | tenant-core-app, CRM, smart-home-app, smart-home-gateway |
| `finance` | Финансы | accountant-service-1 |
| `data` | Дата | Хранилище данных, BI и отчётность |
| `integration` | Интеграционный контур | partner-api-gateway, secret-manager |
| `security` | Аудит и мониторинг | SIEM |

## Таблица ролей

| Роль | Полномочия | Группы пользователей |
|---|---|---|
| `cluster-viewer`<br>*ClusterRole* | Только чтение ресурсов во всех namespace: `get`, `list`, `watch` для pods, services, endpoints, configmaps, PVC, deployments, statefulsets, daemonsets, replicasets, jobs, cronjobs, ingresses, networkpolicies, events, nodes, namespaces, метрик. Доступ к secrets запрещён | Бизнес-аналитики, владельцы продуктов, менеджеры операционных команд, служба поддержки |
| `namespace-viewer`<br>*ClusterRole, назначается через RoleBinding* | Только чтение ресурсов в своём namespace, включая логи подов (`pods/log`). Доступ к secrets запрещён | Разработчики продуктовых команд - в namespace своего домена |
| `namespace-operator`<br>*ClusterRole, назначается через RoleBinding* | Настройка своего namespace: полные права на deployments, statefulsets, daemonsets, replicasets, services, configmaps, endpoints, PVC, ingresses, networkpolicies, jobs, cronjobs, horizontalpodautoscalers; создание и удаление подов; чтение логов, `exec`, `port-forward`. Доступ к secrets запрещён | Инженеры по эксплуатации и DevOps-инженеры продуктовых команд - в namespace своего домена |
| `secret-reader`<br>*Role, отдельно в каждом namespace* | Привилегированное действие: чтение и изменение secrets в конкретном namespace (`get`, `list`, `watch`, `create`, `update`, `patch`, `delete`) | Специалист по ИБ (все namespace); ведущий DevOps-инженер домена - только в namespace своего домена, доступ выдаётся по модели Just-In-Time |
| `security-auditor`<br>*ClusterRole* | Чтение конфигурации безопасности во всех namespace: roles, rolebindings, clusterroles, clusterrolebindings, serviceaccounts, networkpolicies, events, webhook-конфигурации. Чтение значений secrets запрещено - доступны только метаданные (`get`, `list` без `watch` на данные) | Специалист по ИБ, внешние аудиторы на время аудита |
| `platform-admin`<br>*ClusterRole* | Полное управление кластером: namespace, узлы, RBAC-объекты, сетевые политики, ресурсные квоты, CRD. Не включает доступ к secrets прикладных namespace | Платформенная команда, администраторы кластера |
| `ci-deployer`<br>*ClusterRole, назначается через RoleBinding* | Развёртывание в своём namespace: `get`, `list`, `create`, `update`, `patch` для deployments, statefulsets, services, configmaps, jobs. Удаление ресурсов и доступ к secrets запрещены | Сервисные аккаунты CI/CD-конвейеров продуктовых команд |
