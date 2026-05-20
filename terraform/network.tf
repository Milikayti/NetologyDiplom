data "yandex_vpc_network" "default" {
  name = "default"
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "diplom-public-a"
  zone           = var.zone_a
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "diplom-private-a"
  zone           = var.zone_a
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.10.11.0/24"]
  route_table_id = yandex_vpc_route_table.private_nat.id
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "diplom-private-b"
  zone           = var.zone_b
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.10.12.0/24"]
  route_table_id = yandex_vpc_route_table.private_nat.id
}

resource "yandex_vpc_subnet" "private_d" {
  name           = "diplom-private-d"
  zone           = var.zone_d
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.10.13.0/24"]
  route_table_id = yandex_vpc_route_table.private_nat.id
}

resource "yandex_vpc_route_table" "private_nat" {
  name       = "diplom-private-nat-route"
  network_id = data.yandex_vpc_network.default.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "diplom-nat-gateway"

  shared_egress_gateway {}
}
