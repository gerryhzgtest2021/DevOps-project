variable "cluster-name" {
  default = "demo"
}
variable "vpc_public_subnet_ids" {
  description = "public subnet ids of the vpc"
}
variable "vpc_id" {
  description = "the id of vpc"
}