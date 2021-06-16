module "vpc" {
  source = "./modules/vpc"

  az                 = ["us-east-1a", "us-east-1b"]
  private_cidr_block = ["10.0.2.0/24", "10.0.3.0/24"]
  private_number     = 2
  public_cidr_block  = ["10.0.0.0/24", "10.0.1.0/24"]
  public_number      = 2
  vpc_cidr_block     = "10.0.0.0/16"
}