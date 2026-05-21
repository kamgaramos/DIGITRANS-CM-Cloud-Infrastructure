# # ==========================================
# 1. INITIALISATION DES PROVIDERS & BACKEND
# ==========================================
terraform {
  backend "s3" {
    bucket = "agricam-terraform-state-kamga"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ==========================================
# 2. RÉSEAU : VPC & SUBNETS
# ==========================================
resource "aws_vpc" "digitrans_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "digitrans-vpc" }
  lifecycle { ignore_changes = [tags] }
}

resource "aws_subnet" "subnet_az1" {
  vpc_id                  = aws_vpc.digitrans_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "digitrans-subnet-1a" }
}

resource "aws_subnet" "subnet_az2" {
  vpc_id                  = aws_vpc.digitrans_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "digitrans-subnet-1b" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.digitrans_vpc.id
  tags   = { Name = "digitrans-igw" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.digitrans_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.subnet_az1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.subnet_az2.id
  route_table_id = aws_route_table.rt.id
}

# ==========================================
# 3. SÉCURITÉ & IAM
# ==========================================
resource "aws_iam_role" "eks_cluster_role" {
  name = "digitrans-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
  lifecycle { ignore_changes = [tags] }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_nodes_role" {
  name = "digitrans-eks-nodes-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  lifecycle { ignore_changes = [tags] }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes_role.name
}

# ==========================================
# 4. EKS CLUSTER
# ==========================================
resource "aws_eks_cluster" "eks" {
  name     = "digitrans-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config { subnet_ids = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id] }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
  lifecycle { ignore_changes = [tags] }
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "digitrans-node-group"
  node_role_arn   = aws_iam_role.eks_nodes_role.arn
  subnet_ids      = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  instance_types = ["t3.medium"]
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
  lifecycle { ignore_changes = [tags] }
}