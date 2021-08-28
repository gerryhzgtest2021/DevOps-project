data "aws_ami" "eks-workers" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.demo.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}
# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.demo.endpoint}' --b64-cluster-ca '${aws_eks_cluster.demo.certificate_authority[0].data}' '${var.cluster-name}'
USERDATA
}
resource "aws_launch_configuration" "demo" {
  associate_public_ip_address = true
  iam_instance_profile =aws_iam_instance_profile.demo-node.name
  image_id = data.aws_ami.eks-workers.id
  instance_type = "t2.micro"
  name_prefix = "terraform-eks-${var.cluster-name}"
  security_groups = [aws_security_group.demo-node.id]
  user_data_base64 = base64encode(local.demo-node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "demo" {
  desired_capacity = 2
  launch_configuration = aws_launch_configuration.demo.id
  max_size = 2
  min_size = 1
  name = "terraform-eks-${var.cluster-name}"
  vpc_zone_identifier = var.vpc_public_subnet_ids

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "terraform-eks-${var.cluster-name}"
  }
  tag {
    key = "kubernetes.io/cluster/${var.cluster-name}"
    propagate_at_launch = true
    value = "owned"
  }
}