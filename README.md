# Netology Diplom

Дипломная работа: отказоустойчивая инфраструктура для сайта в Yandex Cloud.

## Цель работы

Разработать инфраструктуру для сайта с использованием Terraform и Ansible.

Инфраструктура включает:

- два web-сервера nginx;
- Application Load Balancer;
- bastion host;
- Zabbix Server и Zabbix Agent;
- Elasticsearch;
- Kibana;
- Filebeat;
- snapshots дисков виртуальных машин.

## Документация

- [Основная часть](docs/main.md)
- [Команды и выводы](docs/commands.md)
- [Скриншоты](docs/screenshots.md)

## Структура проекта

- `terraform/` — Terraform-конфигурация Yandex Cloud;
- `ansible/` — Ansible inventory и playbooks;
- `docs/` — описание выполнения работы;
- `screenshots/` — скриншоты результата.

## Проверка

Сайт доступен через Application Load Balancer:

http://84.252.130.22

Zabbix: (Логин\пароль Admin zabbix)

http://130.193.37.5:8080

Kibana:

http://93.77.191.44:5601
