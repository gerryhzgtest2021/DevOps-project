variable "AWS_REGION" {
  default = "us-east-1"
}
variable "vpc_id" {
  type = string
}
variable "vpc_public_subnet_id" {}
variable "vpc_private_subnet_id" {}
variable "env_code" {
  description = "The name of the environment"
  type        = string
}
variable "vpc_cidr" {}
