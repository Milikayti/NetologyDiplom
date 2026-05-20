resource "yandex_vpc_network" "diplom" {
  name = "diplom-vpc"
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "private-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.diplom.id
  route_table_id = yandex_vpc_route_table.private_nat.id
  v4_cidr_blocks = ["10.10.11.0/24"]
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "private-b"
  zone           = var.zone_b
  network_id     = yandex_vpc_network.diplom.id
  route_table_id = yandex_vpc_route_table.private_nat.id
  v4_cidr_blocks = ["10.10.12.0/24"]
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "diplom-nat-gateway"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_nat" {
  name       = "private-nat-route"
  network_id = yandex_vpc_network.diplom.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "private_d" {
  name           = "private-d"
  zone           = var.zone_d
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.13.0/24"]
  route_table_id = yandex_vpc_route_table.private_nat.id
}
