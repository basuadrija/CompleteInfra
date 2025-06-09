provider "aws" {
  region = "ap-south-1" # Change as per your region
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group to allow port 8081
resource "aws_security_group" "nexus_sg" {
  name        = "nexus-sg"
  description = "Allow port 8081 for Nexus"

  ingress {
    description = "Allow Nexus UI"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # open to all; restrict as needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance to run Nexus via Docker
resource "aws_instance" "nexus_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  key_name               = "project" # <-- Replace with your EC2 Key Pair name
  vpc_security_group_ids = [aws_security_group.nexus_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
    newgrp docker <<EONG
    docker run -d --name nexus3 -p 8081:8081 sonatype/nexus3
    EONG
  EOF

  tags = {
    Name = "nexus-docker-instance"
  }
}
