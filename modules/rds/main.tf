data "aws_secretsmanager_secret" "db-password" {
  arn = "arn:aws:secretsmanager:us-east-1:976614466134:secret:password_for_db-RYgwyw"
}

data "aws_secretsmanager_secret_version" "db-password" {
  secret_id = data.aws_secretsmanager_secret.db-password.id
}

locals {
  db-password = jsondecode(data.aws_secretsmanager_secret_version.db-password.secret_string)["password"]
}

resource "aws_db_parameter_group" "mysql-parameters" {
  name        = "${var.env_code}-parameters"
  family      = "mysql8.0"
  description = "${var.env_code} parameters group"
}

resource "aws_db_subnet_group" "mysql-subnet" {
  name        = "${var.env_code}-subnet"
  description = "${var.env_code} subnet group"
  subnet_ids  = var.db-subnet-ids
}

resource "aws_security_group" "allow-mysql" {
  vpc_id      = var.db-vpc-id
  name        = "allow-${var.env_code}"
  description = "allow-${var.env_code}-access"
  ingress {
    from_port   = 3306
    protocol    = "tcp"
    to_port     = 3306
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    self        = true #(Optional) Whether the security group itself will be added as a source to this egress rule.
  }
  tags = {
    Name = "allow-${var.env_code}"
  }
}

resource "aws_db_instance" "mysqldb" {
  allocated_storage = 20
  engine            = "MySQL"
  engine_version    = "8.0.23"
  instance_class    = "db.t2.micro"
  identifier        = "${var.env_code}db"
  name              = "${var.env_code}db"
  username          = "root"
  password          = local.db-password
  #password                = "tempunsecurepassword"
  db_subnet_group_name    = aws_db_subnet_group.mysql-subnet.name
  parameter_group_name    = aws_db_parameter_group.mysql-parameters.name
  multi_az                = var.multi-az
  vpc_security_group_ids  = [aws_security_group.allow-mysql.id]
  storage_type            = "gp2"
  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = {
    Name = "${var.env_code}db-instance"
  }
}
