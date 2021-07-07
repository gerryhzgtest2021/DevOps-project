output "ec2_public_key" {
  value = jsondecode(data.aws_secretsmanager_secret_version.ec2_public_key.secret_string)["public_key"]
}
