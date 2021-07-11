locals {
  aws_region = "us-east-1"
}

provider "aws" {
  region = local.aws_region
}

module "vpc" {
  source             = "./modules/vpc"
  az                 = ["us-east-1a", "us-east-1b"]
  env_code           = "main"
  private_cidr_block = ["10.0.2.0/24", "10.0.3.0/24"]
  public_cidr_block  = ["10.0.0.0/24", "10.0.1.0/24"]
  vpc_cidr_block     = "10.0.0.0/16"
}

module "elb" {
  source = "./modules/elb_auto"

  AWS_REGION            = local.aws_region
  vpc_id                = module.vpc.vpc_id
  vpc_public_subnet_id  = module.vpc.vpc_public_subnet_id
  vpc_private_subnet_id = module.vpc.vpc_private_subnet_id
  env_code              = "example"
  vpc_cidr              = module.vpc.vpc_cidr
}

module "rds" {
  source = "./modules/rds"

  db-subnet-ids = module.vpc.vpc_private_subnet_id
  db-vpc-id     = module.vpc.vpc_id
  multi-az      = false
  vpc_cidr      = module.vpc.vpc_cidr
}
