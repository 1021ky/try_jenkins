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
    key    = "terraform/backend/try_jenkins/ECS"
    region = "us-west-1"
  }
}

# network

resource "aws_vpc" "try-jenkins-on-ecs-dev-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = var.resource_tags["Name"]
    Env         = var.resource_tags["Env"]
    ServiceName = var.resource_tags["ServiceName"]
  }
}

resource "aws_subnet" "try-jenkins-on-ecs-dev-subnet01" {
  vpc_id            = aws_vpc.try-jenkins-on-ecs-dev-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-west-1c"

  map_public_ip_on_launch = true

  tags = {
    Name        = var.resource_tags["Name"]
    Env         = var.resource_tags["Env"]
    ServiceName = var.resource_tags["ServiceName"]
  }
}

resource "aws_route_table" "try-jenkins-on-ecs-dev-public-rtb" {
  vpc_id = aws_vpc.try-jenkins-on-ecs-dev-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.try-jenkins-on-ecs-dev-igw.id
  }

  tags = {
    Name        = var.resource_tags["Name"]
    Env         = var.resource_tags["Env"]
    ServiceName = var.resource_tags["ServiceName"]
  }
}

resource "aws_internet_gateway" "try-jenkins-on-ecs-dev-igw" {
  vpc_id = aws_vpc.try-jenkins-on-ecs-dev-vpc.id
  tags = {
    Name        = var.resource_tags["Name"]
    Env         = var.resource_tags["Env"]
    ServiceName = var.resource_tags["ServiceName"]
  }
}

resource "aws_route_table_association" "try-jenkins-on-ecs-dev-rtb-assoc" {
  subnet_id      = aws_subnet.try-jenkins-on-ecs-dev-subnet01.id
  route_table_id = aws_route_table.try-jenkins-on-ecs-dev-public-rtb.id
}

resource "aws_security_group" "try-jenkins-on-ecs-dev-sg" {
  name        = "${var.name_prefix}-sg"
  description = "Allow SSH HTTP inbound traffic"
  vpc_id      = aws_vpc.try-jenkins-on-ecs-dev-vpc.id

  tags = {
    Name        = var.resource_tags["Name"]
    Env         = var.resource_tags["Env"]
    ServiceName = var.resource_tags["ServiceName"]
  }
}

resource "aws_security_group_rule" "try-jenkins-on-ecs-dev-sg-rule01" {
  # jenkinsへのアクセス許可
  type      = "ingress"
  from_port = 80
  to_port   = 8080
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id = aws_security_group.try-jenkins-on-ecs-dev-sg.id
}

resource "aws_security_group_rule" "try-jenkins-on-ecs-dev-sg-rule02" {
  # ssh用許可
  type = "ingress"

  description       = "SSH from VPC"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["217.178.0.0/16"]
  security_group_id = aws_security_group.try-jenkins-on-ecs-dev-sg.id
}

resource "aws_security_group_rule" "try-jenkins-on-ecs-dev-sg-rule03" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.try-jenkins-on-ecs-dev-sg.id
}

# computing resource

resource "aws_ecs_task_definition" "try-jenkins-on-ecs-dev-ecs-task" {
  family = "try-jenkins-on-ecs-dev-ecs-task"

  requires_compatibilities = ["FARGATE"]

  cpu    = "256" # =0.25vCPU
  memory = "512" # =0.5GB

  network_mode = "awsvpc"

  # ref https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task_definition_parameters.html
  container_definitions = jsonencode(
    [
      {
        name  = "jenkins",
        image = "jenkins/jenkins:2.319.1-jdk11",
        portMappings = [
          {
            containerPort = 8080
            hostPort      = 8080
            protocol      = "tcp"
          }
        ],
        user = "jenkins",
        "environment" : [
          {
            "name" : "CASC_JENKINS_CONFIG",
            "value" : "/usr/share/jenkins/ref/jenkins.yaml"
          }
        ],
      }
    ]
  )
}

resource "aws_ecs_cluster" "try-jenkins-on-ecs-dev-ecs-cluster" {
  name = "${var.name_prefix}-ecs-cluster"
}

resource "aws_ecs_service" "try-jenkins-on-ecs-dev-ecs-service" {
  name            = "${var.name_prefix}-ecs-service"
  cluster         = aws_ecs_cluster.try-jenkins-on-ecs-dev-ecs-cluster.name
  task_definition = aws_ecs_task_definition.try-jenkins-on-ecs-dev-ecs-task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    # タスクの起動を許可するサブネット
    subnets = [
      aws_subnet.try-jenkins-on-ecs-dev-subnet01.id
    ]
    # タスクに紐付けるセキュリティグループ
    security_groups = [
      aws_security_group.try-jenkins-on-ecs-dev-sg.id
    ]
  }

  # デプロイ毎にタスク定義が更新されるため、リソース初回作成時を除き変更を無視
  # ref https://dev.classmethod.jp/articles/terraform-ecs-fargate-apache-run/
  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_key_pair" "try-jenkins-on-ecs-dev-keypair" {
  key_name   = "try-jenkins-on-ecs-dev-keypair"
  public_key = file("./jenkins_key_pair.pub") # `ssh-keygen`コマンドで作成した公開鍵を指定
}

