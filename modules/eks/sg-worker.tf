resource "aws_security_group" "demo-node" {
  name = "${var.cluster-name}-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id = var.vpc_id

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name="${var.cluster-name}-node-sg"
    "kubernetes.io/cluster/${var.cluster-name}"="owned"
  }
}
resource "aws_security_group_rule" "demo-node-ingress-self" {
  description = "allow nodes to communicat with each others"
  from_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.demo-node.id
  source_security_group_id = aws_security_group.demo-node.id
  to_port = 65535
  type = "ingress"
}
resource "aws_security_group_rule" "demo-node-ingress-cluster" {
  description = "allow worker nodes to receive messages from cluster"
  from_port = 1025
  protocol = "tcp"
  security_group_id = aws_security_group.demo-node.id
  source_security_group_id = aws_security_group.demo-cluster.id
  to_port = 65535
  type = "ingress"
}
