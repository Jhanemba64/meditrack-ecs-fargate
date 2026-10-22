output "cloudfront_url" {
  description = "URL publique HTTPS du site statique"
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "ecr_repository_url" {
  description = "Adresse du dépôt ECR privé (pour docker tag / docker push)"
  value       = aws_ecr_repository.api.repository_url
}

output "rds_endpoint" {
  description = "Adresse privée de la base PostgreSQL (= DB_HOST)"
  value       = aws_db_instance.main.address
}

output "rds_secret_arn" {
  description = "Secret Secrets Manager qui contient le mot de passe de la base"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "ecs_cluster_name" {
  description = "Nom du cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nom du service ECS de l'API"
  value       = aws_ecs_service.api.name
}

output "api_url" {
  description = "URL publique de l'API (Load Balancer)"
  value       = "http://${aws_lb.api.dns_name}"
}
