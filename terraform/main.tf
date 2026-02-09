terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------
# VPC
# -------------------
resource "aws_vpc" "student_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "student-vpc"
  }
}

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.student_vpc.id
  cidr_block              = var.public_subnet_az1
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "student-public-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.student_vpc.id
  cidr_block              = var.public_subnet_az2
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "student-public-az2"
  }
}

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.student_vpc.id
  cidr_block        = var.private_subnet_az1
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "student-private-az1"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.student_vpc.id
  cidr_block        = var.private_subnet_az2
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "student-private-az2"
  }
}

# -------------------
# Internet Gateway
# -------------------
resource "aws_internet_gateway" "student_igw" {
  vpc_id = aws_vpc.student_vpc.id

  tags = {
    Name = "student-igw"
  }
}

# -------------------
# Elastic IP for NAT
# -------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "student-nat-eip"
  }

  depends_on = [aws_internet_gateway.student_igw]
}

# -------------------
# NAT Gateway
# -------------------
resource "aws_nat_gateway" "student_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "student-nat"
  }

  depends_on = [aws_internet_gateway.student_igw]
}

# -------------------
# Public Route Table
# -------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.student_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.student_igw.id
  }

  tags = {
    Name = "student-public-rt"
  }
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# -------------------
# Private Route Table
# -------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.student_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.student_nat.id
  }

  tags = {
    Name = "student-private-rt"
  }
}

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private.id
}

# -------------------
# Security Group for EKS Control Plane
# -------------------
resource "aws_security_group" "eks_control_plane" {
  name        = "student-eks-control-plane-sg"
  description = "Security group for EKS control plane"
  vpc_id      = aws_vpc.student_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "student-eks-control-plane-sg"
  }
}

# -------------------
# Security Group for EKS Worker Nodes
# -------------------
resource "aws_security_group" "eks_nodes" {
  name        = "student-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.student_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "student-eks-nodes-sg"
  }
}

# -------------------
# IAM Role for EKS Cluster
# -------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "student-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# -------------------
# IAM Role for EKS Nodes
# -------------------
resource "aws_iam_role" "eks_node_role" {
  name = "student-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# -------------------
# EKS Cluster
# -------------------
resource "aws_eks_cluster" "student_cluster" {
  name     = var.eks_cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = [aws_subnet.public_az1.id, aws_subnet.public_az2.id, aws_subnet.private_az1.id, aws_subnet.private_az2.id]
    security_group_ids      = [aws_security_group.eks_control_plane.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "student-eks-cluster"
  }
}

# -------------------
# EKS Node Group
# -------------------
resource "aws_eks_node_group" "student_nodes" {
  cluster_name    = aws_eks_cluster.student_cluster.name
  node_group_name = "student-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = var.instance_types

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy
  ]

  tags = {
    Name = "student-node-group"
  }
}

# -------------------
# Outputs
# -------------------
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.student_cluster.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.student_cluster.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_security_group.eks_control_plane.id
}

output "eks_node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.student_nodes.id
}
    nodes = {
      desired_size   = 2
      min_size       = 1
      max_size       = 2
      instance_types = ["t3.medium"]
    }
  }
}
