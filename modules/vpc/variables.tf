# Input variable definitions

variable "public_cidr_block" {
  description = "Range of the cidr block for public subnets"
  type        = list(string)
}

variable "private_cidr_block" {
  description = "Range of the cidr block for private subnets"
  type        = list(string)
}

variable "az" {
  description = "Range of the available zones"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "The cidr block of vpc"
  type        = string
}

variable "env_code" {
  description = "The number of the environment"
  type        = string
}
