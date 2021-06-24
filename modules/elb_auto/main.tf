resource "aws_key_pair" "example-keypair" {
  key_name   = "${var.env_code}-keypair"
  public_key = file("./modules/elb_auto/mykey.pub")
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
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["73.126.101.206/32"]
  }

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    security_groups = [aws_security_group.elb-securitygroup.id]
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
  name_prefix     = "${var.env_code}-launchconfig"
  image_id        = data.aws_ami.sample.id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.example-keypair.key_name
  security_groups = [aws_security_group.example-instance.id]
  user_data       = file("./modules/elb_auto/user_data.sh")
}

resource "aws_autoscaling_group" "example-autoscaling" {
  name                      = "${var.env_code}-autoscaling"
  vpc_zone_identifier       = var.vpc_private_subnet_id
  launch_configuration      = aws_launch_configuration.example-launchconfig.name
  max_size                  = 2
  min_size                  = 2
  load_balancers            = [aws_elb.example-elb.name]
  force_delete              = true

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
    interval            = 30
    target              = "HTTP:80/"
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
