provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "hdb_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = {
      Name = "Terraform HDB VPC"
  }
}

resource "aws_internet_gateway" "hdb_ig" {
  vpc_id = aws_vpc.hdb_vpc.id
}

resource "aws_route_table" "hdb_rt" {
  vpc_id = aws_vpc.hdb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hdb_ig.id
  }
}

resource "aws_subnet" "hdb_subnet_a" {
  vpc_id                  = aws_vpc.hdb_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}
resource "aws_route_table_association" "hdb_subnet_a_rta" {
  subnet_id      = aws_subnet.hdb_subnet_a.id
  route_table_id = aws_route_table.hdb_rt.id
}

resource "aws_subnet" "hdb_subnet_b" {
  vpc_id                  = aws_vpc.hdb_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}
resource "aws_route_table_association" "hdb_subnet_b_rta" {
    subnet_id      = aws_subnet.hdb_subnet_b.id
    route_table_id = aws_route_table.hdb_rt.id
}

resource "aws_subnet" "hdb_subnet_c" {
  vpc_id                  = aws_vpc.hdb_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-1c"
  map_public_ip_on_launch = true
}
resource "aws_route_table_association" "hdb_subnet_c_rta" {
    subnet_id      = aws_subnet.hdb_subnet_c.id
    route_table_id = aws_route_table.hdb_rt.id
}

resource "aws_ecs_cluster" "hdb_aws_cluster" {
  name = "hdb_aws_cluster"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

resource "aws_ecs_task_definition" "aws_hdb_task" {
  family                = "aws_hdb_task"
  container_definitions = <<DEFINITION
  [
    {
      "name": "aws_hdb_task",
      "image": "harperdb/harperdb",
      "essential": true,
      "portMappings": [
        { "containerPort": 9925, "hostPort": 9925 },
        { "containerPort": 9926, "hostPort": 9926 },
        { "containerPort": 9927, "hostPort": 9927 }
      ],
      "environment": [
        { "name": "CUSTOM_FUNCTIONS", "value": "true" },
        { "name": "HTTPS_ON", "value": "true" },
        { "name": "HDB_ADMIN_USERNAME", "value": "${var.admin_username}" },
        { "name": "HDB_ADMIN_PASSWORD", "value": "${var.admin_password}" },
        { "name": "CLUSTERING_USER", "value": "${var.cluster_username}" },
        { "name": "CLUSTERING_PASSWORD", "value": "${var.cluster_password}" },
        { "name": "CLUSTERING", "value": "true" },
        { "name": "CLUSTERING_PORT", "value": "9927" },
        { "name": "NODE_NAME", "value": "hdbawsnode" }
      ],
      "memory": 768,
      "cpu": 512
    }
  ]
  DEFINITION
  memory             = 768
  cpu                = 512
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_service" "hdb_aws_service" {
  name            = "hdb_aws_service"
  cluster         = aws_ecs_cluster.hdb_aws_cluster.id
  task_definition = aws_ecs_task_definition.aws_hdb_task.arn
  desired_count   = 1
}

resource "aws_security_group" "ecs_sg" {
    vpc_id              = aws_vpc.hdb_vpc.id

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    ingress {
        from_port       = 9925
        to_port         = 9927
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_launch_configuration" "ecs_launch_config" {
    image_id             = "ami-0416723f8e455592c"
    iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
    security_groups      = [aws_security_group.ecs_sg.id]
    user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.hdb_aws_cluster.name} >> /etc/ecs/ecs.config\necho ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=ec2_instance >> /etc/ecs/ecs.config"
    instance_type        = "t2.micro" # or t3.micro if t2.micro is not available
}

resource "aws_autoscaling_group" "hdb_asg" {
    name                      = "hdb_asg"
    vpc_zone_identifier       = [aws_subnet.hdb_subnet_a.id, aws_subnet.hdb_subnet_b.id, aws_subnet.hdb_subnet_c.id]
    launch_configuration      = aws_launch_configuration.ecs_launch_config.name

    desired_capacity          = 1
    min_size                  = 1
    max_size                  = 1
    health_check_grace_period = 300
    health_check_type         = "EC2"
    tag {
      key                     = "Name"
      value                   = "AWS ECS Instance"
      propagate_at_launch     = true
    }
}
