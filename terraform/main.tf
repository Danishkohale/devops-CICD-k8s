
data "aws_subnet" "default" {
  availability_zone = "us-east-1a"
  default_for_az    = true
}
resource "aws_security_group" "docker" {
  name        = "docker"
  description = "Allow 8080 and 3000 ports"
  vpc_id      = "vpc-0088e74a5cb444339"

  ingress {
    description = "Allow HTTP on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow frontend on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docker"
  }
}

resource "aws_instance" "docker" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids       = [aws_security_group.docker.id]
  key_name                    = var.key_name

  user_data = <<-EOF
                 
                 #!/bin/bash
                 sudo apt update
                 sudo apt-get install unzip
                 sudo apt install -y curl wget apt-transport-https
                 sudo apt install -y docker.io
                 sudo systemctl enable --now docker
                 sudo usermod -aG docker $USER && newgrp docker
                 curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                 unzip awscliv2.zip
                 sudo ./aws/install
                 
                EOF


  tags = {
    Name = "docker"
  }
}

