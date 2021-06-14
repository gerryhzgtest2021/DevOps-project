#Internet VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    
    tags = {
        Name = "main"
    }
}

#Subnets
resource "aws_subnet" "main-public" {
    count = 2
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.${count.index+1}.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "${count.index==0 ? "us-east-1a" : "us-east-1b"}"
    tags = {
        Name = "main-public-${count.index+1}"
    }
}

resource "aws_subnet" "main-private" {
    count = 2
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.${count.index+3}.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "${count.index==0 ? "us-east-1a" : "us-east-1b"}"
    tags = {
        Name = "main-private-${count.index+1}"
    }
}

#Internet GW
resource "aws_internet_gateway" "main-gw" {
    vpc_id = "${aws_vpc.main.id}"
    tags = {
        Name = "main"
    }
}

#Public route table
resource "aws_route_table" "main-public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.main-gw.id}"
    }
    tags = {
        Name = "main-public"
    }
}

#Public subnets route table association
resource "aws_route_table_association" "main-public" {
    count = 2
    subnet_id = "${aws_subnet.main-public[count.index].id}"
    route_table_id = "${aws_route_table.main-public.id}"
}

#NAT GW
resource "aws_eip" "nat" {
    count = 2
    vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
    count = 2
    allocation_id = "${aws_eip.nat[count.index].id}"
    subnet_id = "${aws_subnet.main-public[count.index].id}"
    depends_on = ["aws_internet_gateway.main-gw"]
}

#Private route table
resource "aws_route_table" "main-private" {
    count = 2
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat-gw[count.index].id}"
    }
    tags = {
        Name = "main-private-${count.index+1}"
    }
}

#Private subnets route association
resource "aws_route_table_association" "main-private" {
    count = 2
    subnet_id = "${aws_subnet.main-private[count.index].id}"
    route_table_id = "${aws_route_table.main-private[count.index].id}"
}
