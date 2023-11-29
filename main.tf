provider "aws" {
  region                   = "us-east-2"
  shared_credentials_files = ["~/.aws/credentials"]
}

resource "aws_instance" "this" {
  ami                     = "ami-06d4b7182ac3480fa"
  instance_type           = var.instance_type
  key_name                = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.allow_port.id]
  subnet_id               = aws_subnet.publicsubnet2a.id
    user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y &&
              sudo apt install -y nginx
              echo "Instance Created by Mayur using Terraform" > /var/www/html/index.html
              EOF

  tags = {
    Name = "mayInstanceFromTerra"
  }
}

resource "aws_security_group" "allow_port" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "mayVPC"
  }
}

resource "aws_subnet" "publicsubnet2a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "mayur-public-subnet-1"
  }
}

resource "aws_subnet" "publicsubnet2b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "mayur-public-subnet-2"
  }
}

resource "aws_subnet" "publicsubnet2c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "mayur-public-subnet-3"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "mayur-public_route_table"
  }
}

resource "aws_route_table_association" "public_route_table_2a_association" {
  subnet_id      = aws_subnet.publicsubnet2a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_2b_association" {
  subnet_id      = aws_subnet.publicsubnet2b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_2c_association" {
  subnet_id      = aws_subnet.publicsubnet2c.id
  route_table_id = aws_route_table.public_route_table.id  
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "mayur-internet-gateway"
  }
}

resource "aws_route" "mayur_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

#------------------------ IMPLIMENTING ASG ---------------------------


# implimenting ASG 

# Creating a Launch Configuration for ASG
resource "aws_launch_configuration" "main" {
  name = "may_launch_config"
  image_id = "ami-06d4b7182ac3480fa"
  instance_type = var.instance_type
  key_name = var.key_name

}


# Auto Scaling Group
resource "aws_autoscaling_group" "may_asg" {
  name                 = "may-autoscale_group"
  desired_capacity     = 1
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.publicsubnet2a.id, aws_subnet.publicsubnet2b.id, aws_subnet.publicsubnet2c.id]
  health_check_type    = "EC2"
  health_check_grace_period = 30
  force_delete         = true

  launch_configuration = aws_launch_configuration.main.id

  tag {
    key                 = "name"
    value               = "may_asg"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy for CPU Usage
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "may_scale_up_policy"
  scaling_adjustment    = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 30
  autoscaling_group_name = aws_autoscaling_group.may_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 30
  statistic           = "Average"
  threshold           = 5 # percentage of usage
  alarm_description   = "Scale up when CPU is high"
  alarm_name          = "scale_up_when_cpu_high"
  actions_enabled     = true

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}