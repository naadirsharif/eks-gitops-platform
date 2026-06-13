variable "region" {
}

variable "tags" {
}

variable "name_prefix" {
}

variable "vpc_cidr_block" {
}

variable "zone_id" {
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "base_domain" {
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}