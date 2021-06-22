output "vpc_id" {
  description = "id of the vpc.main"
  value       = aws_vpc.main.id
}

output "vpc_public_subnet_id" {
  description = "public subnet ids"
  value = [aws_subnet.main-public[0].id,aws_subnet.main-public[1].id]
}
