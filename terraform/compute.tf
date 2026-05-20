locals {
  ssh_user = "ubuntu"
  ssh_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFqZlP7dsenDqJmrD86cLJdb2t/pG97Bupi0ldvpsNvX netology-diplom"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = var.zone_a

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion_sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "${local.ssh_user}:${local.ssh_key}"
  }
}
