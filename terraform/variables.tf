variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "zone_a" {
  type = string
}

variable "zone_b" {
  type = string
}

variable "zone_d" {
  type = string
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFqZlP7dsenDqJmrD86cLJdb2t/pG97Bupi0ldvpsNvX netology-diplom"
}
