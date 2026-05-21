# Основная часть дипломной работы

## Подготовка рабочего окружения

Для выполнения дипломной работы была подготовлена локальная рабочая директория `yc-diplom`.

В качестве основных инструментов используются:

* Terraform — для описания и создания облачной инфраструктуры;
* Ansible — для настройки виртуальных машин;
* Yandex Cloud CLI — для работы с облаком Yandex Cloud;
* Git и GitHub — для хранения кода дипломной работы.

Была создана структура проекта:

* `ansible/` — директория для Ansible playbook и inventory;
* `terraform/` — директория с Terraform-конфигурацией;
* `docs/` — документация по выполнению дипломной работы;
* `screenshots/` — скриншоты для подтверждения работы сервисов;
* `.gitignore` — исключения для секретных и служебных файлов;
* `README.md` — главная страница проекта.

В файл `.gitignore` были добавлены исключения для служебных и секретных файлов: Terraform state, tfvars, SSH-ключи, env-файлы и другие данные, которые нельзя публиковать в GitHub.

---

## Подключение к Yandex Cloud

Для подключения к Yandex Cloud была выполнена инициализация CLI:

```bash
yc init
```

В процессе настройки были выбраны:

* cloud: `cloud-ewgen45rus`;
* folder: `default`;
* default zone: `ru-central1-a`.

Для Terraform был создан файл `terraform.tfvars`, содержащий идентификаторы cloud и folder, а также используемые зоны доступности.

Файл `terraform.tfvars` не публикуется в GitHub, так как добавлен в `.gitignore`.

---

## Создание сетевой инфраструктуры

На первом этапе в Terraform была описана базовая сетевая инфраструктура Yandex Cloud.

Были созданы следующие ресурсы:

* VPC `diplom-vpc`;
* публичная подсеть `public-a`;
* приватные подсети `private-a`, `private-b`, `private-d`;
* NAT Gateway для исходящего доступа приватных виртуальных машин в интернет;
* route table `private-nat-route` с маршрутом `0.0.0.0/0` через NAT Gateway.

Публичная подсеть используется для bastion host, Zabbix, Kibana и Application Load Balancer.

Приватные подсети используются для web-серверов и Elasticsearch. Приватные серверы не имеют внешних IP-адресов, а исходящий доступ в интернет получают через NAT Gateway.

---

## Схема инфраструктуры

Инфраструктура построена с разделением на публичный и приватный контуры.

В публичной подсети размещены:

* bastion host;
* Zabbix;
* Kibana;
* Application Load Balancer.

В приватных подсетях размещены:

* web-1;
* web-2;
* Elasticsearch.

Доступ к приватным серверам осуществляется через bastion host с использованием SSH ProxyJump.

Входящий HTTP-трафик распределяется через Application Load Balancer между web-серверами.

Сбор логов nginx осуществляется Filebeat с последующей отправкой в Elasticsearch и визуализацией в Kibana.

---

## Настройка Security Groups

Для ограничения сетевого взаимодействия между сервисами были созданы отдельные Security Groups.

Были настроены следующие правила:

### bastion-sg

* разрешён входящий SSH (22/tcp) из интернета;
* разрешён доступ Zabbix Agent (10050/tcp);
* разрешён весь исходящий трафик.

### web-sg

* разрешён HTTP (80/tcp) от балансировщика;
* разрешён SSH (22/tcp) из подсети bastion host;
* разрешён доступ Zabbix Agent (10050/tcp);
* разрешён исходящий трафик.

### public-services-sg

* разрешён HTTP/HTTPS доступ;
* разрешён SSH доступ;
* разрешён доступ к Zabbix Web Interface (8080/tcp);
* разрешён доступ к Kibana (5601/tcp);
* разрешён исходящий трафик.

### elastic-sg

* разрешён доступ к Elasticsearch (9200/tcp) только из внутренней сети;
* разрешён SSH из подсети bastion host;
* разрешён доступ Zabbix Agent (10050/tcp);
* разрешён исходящий трафик.

Такой подход позволяет минимизировать доступность сервисов извне и соответствует требованиям безопасности.

В процессе создания инфраструктуры была выявлена квота на количество VPC-сетей в Yandex Cloud. Из-за ограничения `vpc.networks.count exceeded` было принято решение использовать существующую сеть `default`, но создать в ней отдельные подсети для дипломной инфраструктуры:

* `diplom-public-a`;
* `diplom-private-a`;
* `diplom-private-b`;
* `diplom-private-d`.

Такой подход позволяет выполнить требования по разделению публичного и приватного контуров, не нарушая лимиты облачного аккаунта.

---

## Создание bastion host

Для безопасного доступа к приватным виртуальным машинам был создан bastion host.

Параметры bastion host:

* ОС: Ubuntu 22.04 LTS;
* 2 vCPU;
* 2 ГБ RAM;
* диск 10 ГБ;
* публичный IP-адрес;
* размещение в публичной подсети `diplom-public-a`.

Для доступа используется SSH-ключ Ed25519.

Bastion host выполняет роль jump host для подключения к виртуальным машинам внутреннего контура без использования внешних IP-адресов на web-серверах и Elasticsearch.

---

## Создание web-серверов

Были созданы два web-сервера:

* `web-1` в зоне `ru-central1-a`;
* `web-2` в зоне `ru-central1-b`.

Серверы размещены в приватных подсетях и не имеют внешних IP-адресов.

Параметры web-серверов:

* Ubuntu 22.04 LTS;
* 2 vCPU;
* 2 ГБ RAM;
* 10 ГБ HDD;
* security group `web-sg`.

Доступ к web-серверам осуществляется через bastion host с использованием SSH ProxyJump.

Разделение web-серверов по зонам доступности обеспечивает отказоустойчивость сайта.

---

## Создание виртуальных машин

В рамках инфраструктуры были созданы следующие виртуальные машины:

* `bastion` — публичная ВМ для SSH-доступа к приватным серверам;
* `web-1` — первый web-сервер в приватной подсети;
* `web-2` — второй web-сервер в приватной подсети;
* `zabbix` — сервер мониторинга в публичной подсети;
* `elastic` — сервер Elasticsearch в приватной подсети;
* `kibana` — сервер Kibana в публичной подсети.

Web-серверы и Elasticsearch не имеют внешних IP-адресов. Доступ к ним осуществляется через bastion host с использованием SSH ProxyJump.

Проверка доступа к приватным серверам была выполнена командами:

```bash
ssh -J ubuntu@111.88.248.75 ubuntu@10.10.11.10 hostname
ssh -J ubuntu@111.88.248.75 ubuntu@10.10.12.13 hostname
ssh -J ubuntu@111.88.248.75 ubuntu@10.10.13.6 hostname
```

В результате были получены ответы:

```text
web-1
web-2
elastic
```

---

## Настройка web-серверов через Ansible

Для настройки web-серверов был создан Ansible inventory с использованием внутренних FQDN-имён виртуальных машин в зоне `.ru-central1.internal`.

Подключение к приватным серверам выполняется через bastion host с использованием SSH ProxyJump.

На серверах `web-1` и `web-2` был установлен nginx и создана тестовая HTML-страница.

Проверка работы nginx была выполнена командами:

```bash
ssh -J ubuntu@111.88.248.75 ubuntu@web-1.ru-central1.internal "curl -s http://localhost"

ssh -J ubuntu@111.88.248.75 ubuntu@web-2.ru-central1.internal "curl -s http://localhost"
```

Оба web-сервера вернули HTML-страницу с указанием своего FQDN.

---

## Настройка Application Load Balancer

Для распределения входящего HTTP-трафика был создан Application Load Balancer.

В Terraform были описаны следующие ресурсы:

* Target Group с двумя web-серверами;
* Backend Group с HTTP backend на порт 80;
* Healthcheck на путь `/`;
* HTTP Router;
* Virtual Host;
* Application Load Balancer с публичным listener на порт 80.

Публичный IP-адрес балансировщика:

```text
84.252.130.22
```

Работа балансировщика была проверена командой:

```bash
curl -v http://84.252.130.22:80
```

В результате был получен ответ:

```text
HTTP/1.1 200 OK
```

и HTML-страница web-сервера.

---

## Обеспечение отказоустойчивости

Для повышения отказоустойчивости web-серверы были размещены в разных зонах доступности:

* `web-1` — `ru-central1-a`;
* `web-2` — `ru-central1-b`.

Application Load Balancer выполняет healthcheck backend-серверов и автоматически исключает недоступные узлы из балансировки.

Разделение серверов по зонам доступности позволяет сохранить работоспособность сервиса при отказе одной из зон.

---

## Настройка Zabbix Server

Для мониторинга инфраструктуры был развёрнут Zabbix Server на отдельной виртуальной машине `zabbix`.

Zabbix был установлен с помощью Ansible playbook и Docker Compose.

В состав Zabbix stack входят:

* PostgreSQL;
* Zabbix Server;
* Zabbix Web Interface.

Веб-интерфейс Zabbix доступен по адресу:

```text
http://130.193.37.5:8080
```

Проверка доступности была выполнена командой:

```bash
curl -I http://130.193.37.5:8080
```

В результате был получен ответ:

```text
HTTP/1.1 200 OK
```

---

## Настройка Zabbix Agent

На все виртуальные машины был установлен `zabbix-agent` с помощью Ansible.

Agent установлен на:

* bastion;
* web-1;
* web-2;
* zabbix;
* elastic;
* kibana.

В конфигурации агента указан Zabbix Server:

```text
10.10.1.11
```

Проверка состояния агента была выполнена командой:

```bash
ansible all -m shell -a "systemctl is-active zabbix-agent"
```

На всех серверах получен статус:

```text
active
```

---

## Настройка Elasticsearch

Для хранения логов nginx был развёрнут Elasticsearch на отдельной виртуальной машине `elastic`.

Сервер `elastic` размещён в приватной подсети и не имеет внешнего IP-адреса.

Elasticsearch был установлен с помощью Ansible и Docker Compose.

Проверка работы была выполнена командой:

```bash
ssh -J ubuntu@111.88.248.75 ubuntu@elastic.ru-central1.internal "curl -s http://localhost:9200"
```

В результате Elasticsearch вернул информацию о кластере `docker-cluster` и версию `8.13.4`.

---

## Настройка Kibana

Для визуализации и анализа логов была развёрнута Kibana на отдельной виртуальной машине `kibana`.

Kibana была установлена с помощью Ansible и Docker Compose.

В конфигурации Kibana указан Elasticsearch:

```text
http://elastic.ru-central1.internal:9200
```

Веб-интерфейс Kibana доступен по адресу:

```text
http://93.77.191.44:5601
```

Проверка работы была выполнена командами:

```bash
ssh ubuntu@93.77.191.44 "sudo docker ps"

ssh ubuntu@93.77.191.44 "sudo docker logs --tail=30 kibana"
```

В логах контейнера получено сообщение:

```text
Kibana is now available
```

---

## Настройка Filebeat

Для сбора логов nginx на web-серверах был установлен Filebeat.

Так как скачивание пакетов Elastic может быть недоступно, Filebeat был развёрнут в Docker-контейнере на каждом web-сервере.

Filebeat собирает следующие файлы:

* `/var/log/nginx/access.log`;
* `/var/log/nginx/error.log`.

Логи отправляются в Elasticsearch:

```text
http://elastic.ru-central1.internal:9200
```

Проверка индексов Elasticsearch была выполнена командой:

```bash
ssh -J ubuntu@111.88.248.75 ubuntu@elastic.ru-central1.internal "curl -s 'http://localhost:9200/_cat/indices?v'"
```

В результате был создан индекс Filebeat:

```text
.ds-filebeat-8.13.4-2026.05.21-000001
```

---

## Snapshot Elasticsearch

Для резервного копирования данных Elasticsearch был настроен snapshot repository `netology_backup`.

На сервере `elastic` была создана директория:

```text
/opt/elasticsearch-backup
```

Она была подключена в Docker Compose как volume и указана в параметре Elasticsearch `path.repo`.

Был создан snapshot:

```text
snapshot_1
```

Проверка создания snapshot показала состояние:

```text
SUCCESS
```

Количество успешных shard: 29.

Количество failed shard: 0.

---

## Snapshot виртуальных машин

Для резервного копирования инфраструктуры были созданы snapshots всех виртуальных машин в Yandex Cloud.

Созданы snapshots:

* bastion-snapshot;
* web1-snapshot;
* web2-snapshot;
* elastic-snapshot;
* kibana-snapshot;
* zabbix-snapshot.

Проверка была выполнена командой:

```bash
yc compute snapshot list
```

Все snapshots имеют статус:

```text
READY
```

---

## Итоги работы

В рамках дипломной работы была создана отказоустойчивая инфраструктура в Yandex Cloud с использованием Terraform и Ansible.

Были реализованы:

* разделение публичного и приватного контуров;
* bastion host для безопасного доступа;
* отказоустойчивые web-серверы;
* Application Load Balancer;
* централизованный сбор логов через Filebeat;
* Elasticsearch и Kibana для анализа логов;
* мониторинг инфраструктуры через Zabbix;
* резервное копирование виртуальных машин и Elasticsearch snapshots.

Вся инфраструктура описана как код (Infrastructure as Code) и хранится в GitHub-репозитории.
