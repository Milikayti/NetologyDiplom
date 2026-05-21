resource "yandex_vpc_security_group" "bastion_sg" {
  name       = "bastion-sg"
  network_id = data.yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from internet"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
