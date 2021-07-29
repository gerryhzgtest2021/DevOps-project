output "db_password" {
  value = local.db-password
}
output "db_endpoint" {
  value = aws_db_instance.mysqldb.endpoint
}
output "db_address" {
  value = aws_db_instance.mysqldb.address
}
