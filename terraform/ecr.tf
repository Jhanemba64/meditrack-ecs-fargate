# Dépôt ECR privé de l'image de l'API

resource "aws_ecr_repository" "api" {
  name = "${var.project}-api"

  # Un tag publié ne peut pas être réécrit
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # Permet à terraform destroy de supprimer le dépôt même s'il contient des images
  force_delete = true

  tags = { Name = "${var.project}-api-ecr" }
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Garder les 10 dernieres images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
