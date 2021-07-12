variable "db-subnet-ids" {
  description = "the IDs of subnets where the database locates"
  type        = list(string)
}

variable "db-vpc-id" {
  description = "the ID of the VPC where the database locates"
  type        = string
}

variable "multi-az" {
  description = "Whether deploy multi-az"
  type        = bool
}

variable "vpc_cidr" {}

variable "env_code" {
  description = "The name of the environment"
  type        = string
}
