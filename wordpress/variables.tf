variable "db_password" {
}

variable "name" {
}

variable "sec_group" {
  type = "list"
}

variable "keypair" {
}

variable "flavor" {
  default = "e3standard.x3"
}

variable "network_name" {
}

variable "discovery" {
  default = "true"
}

variable "external" {
  default = "false"
}

variable "region" {
  default = "it-mil1"
}
