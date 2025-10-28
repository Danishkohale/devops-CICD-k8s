
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

resource "aws_instance" "k8s" {
  ami                         = var.ami_id
  instance_type               = var.k8s_instance
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.docker.id]
  key_name                    = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -eux

    apt update -y
    apt install -y unzip
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER && newgrp docker

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    minikube start --driver=docker --vm=true 



    echo "Setup complete"
  EOF

  tags = {
    Name = "k8s"
  }




resource "aws_iam_role" "eks_cluster_role" {
  name = "two-tier"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_role" "eks_node_role" {
  name = "two-tier"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}



resource "aws_eks_cluster" "simple_cluster" {
  name     = "simple-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.existing_subnets.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}


resource "aws_eks_node_group" "simple_nodes" {
  cluster_name    = aws_eks_cluster.simple_cluster.name
  node_group_name = "simple-nodegroup"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.existing_subnets.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.worker_node,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly
  ]
}

}

  


