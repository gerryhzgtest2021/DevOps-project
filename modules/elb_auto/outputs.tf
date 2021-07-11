output "ec2_public_key" {
  value = jsondecode(data.aws_secretsmanager_secret_version.ec2_public_key.secret_string)["public_key"]
}

output "example-instance-security-group-id" {
  value = aws_security_group.example-instance.id
}
