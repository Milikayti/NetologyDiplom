# Основные команды проверки

## Проверка Terraform

terraform validate
terraform plan

## Проверка виртуальных машин

yc compute instance list

## Проверка ALB

curl -v http://84.252.130.22

## Проверка Elasticsearch

curl http://localhost:9200

## Проверка индексов

curl http://localhost:9200/_cat/indices?v

## Проверка snapshots

yc compute snapshot list

## Проверка Ansible

ansible all -m ping
