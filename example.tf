provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"

  az                 = ["us-east-1a", "us-east-1b"]
  private_cidr_block = ["10.0.2.0/24", "10.0.3.0/24"]
  public_cidr_block  = ["10.0.0.0/24", "10.0.1.0/24"]
  vpc_cidr_block     = "10.0.0.0/16"
  env_code           = "main"
}
