# ==========================================
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
  tags = { Name = "digitrans-vpc" }
  lifecycle { ignore_changes = [tags] }
}

resource "aws_subnet" "subnet_az1" {
  vpc_id                  = aws_vpc.digitrans_