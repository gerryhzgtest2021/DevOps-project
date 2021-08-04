data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "db-password" {
  arn = "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:password_for_db-RYgwyw"
}

data "aws_secretsmanager_secret_version" "db-password" {
  secret_id = data.aws_secretsmanager_secret.db-password.id
}

data "aws_ami" "sample" {
  owners     = ["amazon"]
  name_regex = "amzn2-ami-hvm-2\\.0\\.20210525\\.0-x86_64-gp2"
}

locals {
  aws_region   = "us-east-1"
  db-password  = jsondecode(data.aws_secretsmanager_secret_version.db-password.secret_string)["password"]
  env_code_elb = "example"
  local_ip     = "76.185.25.233/32"
}

provider "aws" {
  region = local.aws_region
}

module "example-instance-securitygroup" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4"
  name        = "${local.env_code_elb}-instance"
  description = "security group for my instance"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]
  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.elb-securitygroup.security_group_id
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = {
    Name = "${local.env_code_elb}-instance"
  }
}

module "elb-securitygroup" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4"
  name        = "${local.env_code_elb}-ELB"
  description = "security group for load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = local.local_ip
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = {
    Name = "${local.env_code_elb}-ELB"
  }
}

module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.0"

  trusted_role_arns = [
    "arn:aws:iam::307990089504:root",
  ]
  trusted_role_services = ["ec2.amazonaws.com"]

  create_role             = true
  create_instance_profile = true

  role_name         = "ec2-iam-role"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
  number_of_custom_role_policy_arns = 1
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"
  # insert the 19 required variables here

  azs             = ["us-east-1a", "us-east-1b"]
  name            = "main"
  private_subnets = ["10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  cidr            = "10.0.0.0/16"
  #vpc
  enable_dns_hostnames = true
  enable_classiclink   = false
  #NAT Gateway
  enable_nat_gateway = true
}

module "mysql_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4"
  name        = "allow-mysql"
  description = "allow-mysql-access"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "mysql access within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]
  tags = {
    Name = "allow-mysql"
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "3.3.0"
  # insert the 29 required variables here
  identifier             = "mysql"
  engine                 = "MySQL"
  engine_version         = "8.0.23"
  family                 = "mysql8.0" # DB parameter group
  major_engine_version   = "8.0"      # DB option group
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  max_allocated_storage  = 50
  storage_encrypted      = false
  name                   = "mysqldb"
  username               = "root"
  password               = local.db-password
  port                   = 3306
  multi_az               = false
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.mysql_sg.security_group_id]

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.4.0"
  # insert the 56 required variables here
  name                      = "example"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  load_balancers            = [module.elb_http.this_elb_name]
  health_check_type         = "ELB"
  vpc_zone_identifier       = module.vpc.private_subnets
  # Launch template
  lt_name                   = "example-launchconfig"
  description               = "Launch template example"
  update_default_version    = true
  use_lc                    = true
  create_lc                 = true
  image_id                  = data.aws_ami.sample.id
  instance_type             = "t2.micro"
  user_data                 = templatefile("${path.module}/user_data.tpl", { db_password = local.db-password, db_address = module.rds.db_instance_address, db_name = module.rds.db_instance_name })
  security_groups           = [module.example-instance-securitygroup.security_group_id]
  iam_instance_profile_name = module.iam_assumable_role.this_iam_instance_profile_name
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "${local.env_code_elb}-elb"

  create_elb      = true
  subnets         = module.vpc.public_subnets
  security_groups = [module.elb-securitygroup.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    },
  ]

  health_check = {
    target              = "tcp:80"
    interval            = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
  }

  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${local.env_code_elb}-elb"
  }
}
