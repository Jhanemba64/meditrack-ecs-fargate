# Variables du projet

variable "aws_region" {
  description = "Région AWS où déployer (Paris pour la conformité HDS)"
  type        = string
  default     = "eu-west-3"
}

variable "aws_profile" {
  description = "Profil AWS CLI à utiliser (utilisateur IAM de déploiement dédié)"
  type        = string
  default     = "meditrack"
}

variable "environment" {
  description = "Nom de l'environnement (permet de séparer test / prod)"
  type        = string
  default     = "production"
}

variable "project" {
  description = "Préfixe utilisé pour nommer les ressources"
  type        = string
  default     = "meditrack"
}

# Réseau

variable "vpc_cidr" {
  description = "Plage d'adresses IP privées du réseau VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Sous-réseaux publics (1 par zone) : Load Balancer + NAT"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Sous-réseaux privés (1 par zone) : conteneurs ECS + base RDS"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# Base de données

variable "db_instance_class" {
  description = "Taille de l'instance RDS (db.t3.micro demandé par le sujet)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Nom de la base PostgreSQL utilisée par l'API"
  type        = string
  default     = "meditrack"
}

variable "db_username" {
  description = "Utilisateur principal de la base (le mot de passe est généré par AWS)"
  type        = string
  default     = "meditrack_admin"
}

# API

variable "api_image_tag" {
  description = "Tag de l'image Docker de l'API dans ECR (= version du package.json)"
  type        = string
  default     = "1.1.0"
}

variable "api_port" {
  description = "Port sur lequel l'API écoute dans le conteneur"
  type        = number
  default     = 3000
}

variable "api_desired_count" {
  description = "Nombre de conteneurs de l'API (2 = un par zone, haute disponibilité)"
  type        = number
  default     = 2
}
