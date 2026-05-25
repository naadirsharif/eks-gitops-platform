# Fetch available availability zones in the current region

data "aws_availability_zones" "available" {
  state = "available"
}