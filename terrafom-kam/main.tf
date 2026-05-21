# ==========================================
# 1. INITIALISATION DES PROVIDERS & BACKEND
# ==========================================
terraform {
  # --- AJOUT DU BACKEND S3 POUR LE PIPELINE CI/CD ---
  backend "s3" {
    bucket = "mon-bucket-terraform-digitrans-unique" # REMPLACE PAR UN NOM UNIQUE (ex: ton-nom-digitrans-terraform)
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  # --------------------------------------------------

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
# ... (le reste de ton code ne change pas)
