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

# Scaling config
variable "node_desired_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "node_min_size" {
  type = number
}