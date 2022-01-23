# 命名規則は右記を参考 https://dev.classmethod.jp/articles/aws-name-rule/

provider "aws" {
  profile = "default"
  region  = "us-west-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.72"
    }
  }
  required_version = ">= 0.14.9"
  backend "s3" {
    bucket = "dev.ksanchu"
    key    = "terraform/backend/try_jenkins"
    region = "us-west-1"
  }
}

# network

resource "aws_vpc" "try-jenkins-dev-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "try-jenkins-dev-vpc"
    Env         = "dev"
    ServiceName = "try-jenkins"
  }
}

resource "aws_subnet" "try-jenkins-dev-subnet01" {
  vpc_id            = aws_vpc.try-jenkins-dev-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-west-1c"

  map_public_ip_on_launch = true

  tags = {
    Name        = "try-jenkins-dev-subnet01"
    Env         = "dev"
    ServiceName = "try-jenkins"
  }
}

resource "aws_route_table" "try-jenkins-dev-public-rtb" {
  vpc_id = aws_vpc.try-jenkins-dev-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.try-jenkins-dev-igw.id
  }

  tags = {
    Name        = "try-jenkins-dev-public-rtb"
    Env         = "dev"
    ServiceName = "try-jenkins"
  }
}

resource "aws_internet_gateway" "try-jenkins-dev-igw" {
  vpc_id = aws_vpc.try-jenkins-dev-vpc.id
  tags = {
    Name        = "try-jenkins-dev-igw"
    Env         = "dev"
    ServiceName = "try-jenkins"
  }
}

resource "aws_route_table_association" "try-jenkins-dev-rtb-assoc" {
  subnet_id      = aws_subnet.try-jenkins-dev-subnet01.id
  route_table_id = aws_route_table.try-jenkins-dev-public-rtb.id
}

resource "aws_security_group" "try-jenkins-dev-sg" {
  name        = "try-jenkins-dev-sg"
  description = "Allow SSH HTTP inbound traffic"
  vpc_id      = aws_vpc.try-jenkins-dev-vpc.id

  tags = {
    Name        = "try-jenkins-dev-sg"
    Env         = "dev"
    ServiceName = "try-jenkins"
  }
}

resource "aws_security_group_rule" "try-jenkins-dev-sg-rule01" {
  type      = "ingress"
  from_port = 80
  to_port   = 8080
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id = aws_security_group.try-jenkins-dev-sg.id
}

resource "aws_security_group_rule" "try-jenkins-dev-sg-rule02" {
  type = "ingress"

  description       = "SSH from VPC"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["217.178.0.0/16"]
  security_group_id = aws_security_group.try-jenkins-dev-sg.id
}

resource "aws_security_group_rule" "try-jenkins-dev-sg-rule03" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.try-jenkins-dev-sg.id
}

# computing resource

data "aws_ssm_parameter" "amazon-linux2-latest-ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "try-jenkins-dev-ec2" {
  ami           = data.aws_ssm_parameter.amazon-linux2-latest-ami.value
  instance_type = "t2.micro"
  key_name      = aws_key_pair.try-jenkins-dev-keypair.id
  subnet_id     = aws_subnet.try-jenkins-dev-subnet01.id
  vpc_security_group_ids = [
    aws_security_group.try-jenkins-dev-sg.id
  ]

  tags = {
    Name        = "try-jenkins-dev-ec2"
    Env         = "dev"
    ServiceName = "try-jenkins"
  }
}

resource "aws_eip" "try-jenkins-dev-eip" {
  instance = aws_instance.try-jenkins-dev-ec2.id
  vpc      = true
}


resource "aws_key_pair" "try-jenkins-dev-keypair" {
  key_name   = "try-jenkins-dev-keypair"
  public_key = file("./jenkins_key_pair.pub") # `ssh-keygen`コマンドで作成した公開鍵を指定
}