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

module "hello_world_lambda" {
  source = "../../modules/lambda"

  project_name  = var.project_name
  function_name = var.lambda_function_name
  description   = var.lambda_description

  package_type = "Zip"
  runtime      = var.lambda_runtime
  handler      = var.lambda_handler
  source_dir   = "${path.module}/src/hello_world"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = values(module.vpc.private_subnet_ids)
}
