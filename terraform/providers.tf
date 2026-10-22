# Terraform et fournisseur AWS

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69"
    }
  }
}

# Profil "meditrack" (utilisateur IAM de déploiement), région Paris pour l'hébergement des données en France.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Tags appliqués à toutes les ressources du projet
  default_tags {
    tags = {
      Project     = "MediTrack"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
