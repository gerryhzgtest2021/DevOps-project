data "aws_secretsmanager_secret" "ec2_public_key" {
  arn = "arn:aws:secretsmanager:us-east-1:976614466134:secret:public_key_for_ec2-ebmj3R"
}

data "aws_secretsmanager_secret_version" "ec2_public_key" {
  secret_id = data.aws_secretsmanager_secret.ec2_public_key.id
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")
  vars = {
    wordpress_conf = file("${path.module}/wordpress_conf.txt")
    localhost_php  = file("${path.module}/localhost_php.txt")
    db_password    = var.db_password
    db_endpoint    = var.db_endpoint
  }
}

locals {
  ec2_public_key = jsondecode(data.aws_secretsmanager_secret_version.ec2_public_key.secret_string)["public_key"]
}

resource "aws_key_pair" "example-keypair" {
  key_name   = "${var.env_code}-keypair"
  public_key = local.ec2_public_key
}

resource "aws_iam_role" "ec2-iam-role" {
  name = "ec2-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm-ec2-role-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2-iam-role.name
}

resource "aws_iam_instance_profile" "ssm-ec2-role-instance-profile" {
  name = "ssm-ec2-role"
  role = aws_iam_role.ec2-iam-role.name
}

resource "aws_security_group" "example-instance" {
  vpc_id      = var.vpc_id
  name        = "${var.env_code}-instance"
  description = "security group for my instance"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    security_groups = [aws_security_group.elb-securitygroup.id]
  }
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.env_code}-instance"
  }
}

resource "aws_security_group" "elb-securitygroup" {
  vpc_id      = var.vpc_id
  name        = "${var.env_code}-ELB"
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
    cidr_blocks = ["76.185.25.233/32"]
  }

  tags = {
    Name = "${var.env_code}-ELB"
  }
}

data "aws_ami" "sample" {
  owners     = ["amazon"]
  name_regex = "amzn2-ami-hvm-2\\.0\\.20210525\\.0-x86_64-gp2"
}

resource "aws_launch_configuration" "example-launchconfig" {
  name_prefix          = "${var.env_code}-launchconfig"
  image_id             = data.aws_ami.sample.id
  instance_type        = "t2.micro"
  key_name             = aws_key_pair.example-keypair.key_name
  security_groups      = [aws_security_group.example-instance.id]
  user_data            = templatefile("${path.module}/user_data.tpl", {db_password = var.db_password, db_endpoint = var.db_endpoint})
  iam_instance_profile = aws_iam_instance_profile.ssm-ec2-role-instance-profile.name
}

resource "aws_autoscaling_group" "example-autoscaling" {
  name                 = "${var.env_code}-autoscaling"
  vpc_zone_identifier  = var.vpc_private_subnet_id
  launch_configuration = aws_launch_configuration.example-launchconfig.name
  max_size             = 1
  min_size             = 1
  load_balancers       = [aws_elb.example-elb.name]
  force_delete         = true

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "ec2 instance"
  }
}

resource "aws_elb" "example-elb" {
  name            = "${var.env_code}-elb"
  subnets         = var.vpc_public_subnet_id
  security_groups = [aws_security_group.elb-securitygroup.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 5
    target              = "tcp:80"
    timeout             = 3
    unhealthy_threshold = 2
  }

  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${var.env_code}-elb"
  }
}
