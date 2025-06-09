provider "aws" {
  region = "ap-south-1"  # change region as per your need
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amzn_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group to allow port 22 (SSH) and 9000 (SonarQube)
resource "aws_security_group" "sonarqube_sg" {
  name        = "sonarqube-sg"
  description = "Allow SSH and SonarQube port"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # You can restrict this to your IP
  }

  ingress {
    description = "SonarQube UI"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Accessible from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "sonarqube_instance" {
  ami                    = data.aws_ami.amzn_linux_2.id
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.sonarqube_sg.id]
  key_name               = "project"  # Replace with your key name

  user_data = <<-EOF
    #!/bin/bash
    # Step 1: Update the system
    sudo yum update -y

    # Step 2: Install Java 17
    sudo yum install -y java-17-amazon-corretto-headless unzip wget

    # Step 3: Add user 'sonarqube'
    sudo adduser sonarqube

    # Step 4 & 5: Switch to sonarqube user and download SonarQube
    sudo -u sonarqube bash -c "
      cd /home/sonarqube
      wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip
      unzip sonarqube-10.4.1.88267.zip
    "

    # Step 6: Set permissions
    sudo chown -R sonarqube:sonarqube /home/sonarqube/sonarqube-10.4.1.88267
    sudo chmod -R 755 /home/sonarqube/sonarqube-10.4.1.88267

    # Step 7: Start SonarQube
    sudo -u sonarqube bash -c "
      cd /home/sonarqube/sonarqube-10.4.1.88267/bin/linux-x86-64/
      ./sonar.sh start
    "
  EOF

  tags = {
    Name = "SonarQube-Instance"
  }
}
