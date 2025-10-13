resource "aws_security_group" "jenkins_sg" {
  name        = var.jenkins_name
  

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = var.k8s_name

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  security_groups        = [aws_security_group.jenkins_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-11-amazon-corretto
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              yum install -y jenkins git docker
              systemctl enable jenkins
              systemctl start jenkins
              systemctl enable docker
              systemctl start docker
              usermod -aG docker jenkins
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}

resource "aws_instance" "k8s_node" {
  ami                    = var.ami_id
  instance_type          = "t2.medium"
  key_name               = var.key_name
  security_groups        = [aws_security_group.k8s_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker conntrack
              systemctl enable docker && systemctl start docker
              curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
              install minikube-linux-amd64 /usr/local/bin/minikube
              minikube start --driver=docker
              EOF

  tags = {
    Name = "K8s-Cluster"
  }
}
