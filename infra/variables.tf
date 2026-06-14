variable "region" {
}

variable "vpc_cidr_block" {
}

variable "owner" {
}

variable "environment" {
}

variable "base_domain" {
}

variable "sub_domain" {
}

variable "project_name" {
}

variable "zone_id" {
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

# Node Scaling config
variable "node_desired_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "node_min_size" {
  type = number
}