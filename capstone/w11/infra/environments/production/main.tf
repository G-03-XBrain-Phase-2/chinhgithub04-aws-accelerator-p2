module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  vpc_cidr              = var.vpc_cidr
  public_subnets        = var.public_subnets
  private_subnets       = var.private_subnets
  database_subnets      = var.database_subnets
  nat_gateways          = var.nat_gateways
  private_route_tables  = var.private_route_tables
  database_route_tables = var.database_route_tables
}
