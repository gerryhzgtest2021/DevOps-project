variable "AWS_REGION" {
  default = "us-east-1"
}
variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-0aeeebd8d2ab47354"
    us-west-1 = "ami-0b2ca94b5b49e0132"
    eu-west-1 = "ami-0ac43988dfd31ab9a"
  }
}
