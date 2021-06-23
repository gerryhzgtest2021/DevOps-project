provider "aws" {
  region = var.AWS_REGION
}
#call vpc module
module "vpc" {
  source             = "../vpc"
  az                 = ["us-east-1a", "us-east-1b"]
  env_code           = "main"
  private_cidr_block = ["10.0.2.0/24", "10.0.3.0/24"]
  public_cidr_block  = ["10.0.0.0/24", "10.0.1.0/24"]
  vpc_cidr_block     = "10.0.0.0/16"
}
#aws keypair
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = "./modules/elb_auto/mykey.pub"
}
#security groups
resource "aws_security_group" "myinstance" {
  vpc_id      = module.vpc.vpc_id
  name        = "myinstance"
  description = "security group for my instance"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tpc"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    security_groups = [aws_security_group.elb-securitygroup.id]
  }

  tags = {
    Name = "myinstance"
  }
}

resource "aws_security_group" "elb-securitygroup" {
  vpc_id      = module.vpc.vpc_id
  name        = "ELB"
  description = "security group for load balancer"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ELB"
  }
}

#launch configuration
resource "aws_launch_configuration" "example-launchconfig" {
  name_prefix     = "example-launchconfig"
  image_id        = lookup(var.AMIS, var.AWS_REGION)
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.mykeypair.key_name
  security_groups = [aws_security_group.myinstance.id]
  user_data       = "#!/bin/bash\nmkdir git_clone\ncd git_clone\ngit clone https://github.com/gabrielecirulli/2048\nsudo yum update -y\nsudo yum install -y httpd\ncp . /var/www/html/\nsudo systemctl start httpd\nsudo systemctl enable httpd"
}

#auto scaling group
resource "aws_autoscaling_group" "example-autoscaling" {
  name                      = "example-autoscaling"
  vpc_zone_identifier       = module.vpc.vpc_public_subnet_id
  launch_configuration      = aws_launch_configuration.example-launchconfig.name
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  load_balancers            = [aws_elb.my-elb.name]
  force_delete              = true

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "ec2 instance"
  }
}

#elb
resource "aws_elb" "my-elb" {
  name            = "my-elb"
  subnets         = module.vpc.vpc_public_subnet_id
  security_groups = [aws_security_group.elb-securitygroup.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 30
    target              = "HTTP:80/"
    timeout             = 3
    unhealthy_threshold = 2
  }

  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "my-elb"
  }
}
