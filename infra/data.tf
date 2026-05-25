# Fetch available availability zones in the current region
# based on the configured provider region

data "aws_availability_zones" "available" {
  state = "available"
}