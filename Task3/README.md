# Task3 - Внешние интеграции: сервисы Умный дом

| Файл | Содержание |
|---|---|
| [`diagrams/c1-context-smart-home.puml`](./diagrams/c1-context-smart-home.puml) | Диаграмма контекста C4 |
| [`diagrams/img/c1-context-smart-home.png`](./diagrams/img/c1-context-smart-home.png) | Отрендеренная диаграмма контекста |
| [`diagrams/c2-containers-to-be.drawio`](./diagrams/c2-containers-to-be.drawio) | Доработанная диаграмма контейнеров компании |
| [`diagrams/img/c2-containers-to-be.png`](./diagrams/img/c2-containers-to-be.png) | Отрендеренная диаграмма контейнеров |
| [`diagrams/c2-containers-as-is.drawio`](./diagrams/c2-containers-as-is.drawio) | Исходная диаграмма контейнеров компании |
| [`integration-requirements.md`](./integration-requirements.md) | Требования к внешним интеграциям |

Диаграмма контейнеров получена доработкой исходной диаграммы компании.

Добавленные контейнеры: smart-home-app, smart-home-db, smart-home-gateway,
smart-home-events, partner-api-gateway, secret-manager, подсистема аудита и мониторинга.
Внешняя система: партнёрская платформа Умный дом.

Диаграмма контекста - PlantUML: `java -jar plantuml.jar -tpng -o img diagrams/c1-context-smart-home.puml`
