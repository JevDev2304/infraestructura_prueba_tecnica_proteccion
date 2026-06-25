output "ecr_repository_url" {
  description = "URL del repositorio ECR. Usar para hacer push de la imagen: docker push <url>:<tag>"
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  description = "Endpoint de la instancia RDS PostgreSQL. Configurar como DB_URL en la Task Definition de ECS"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.app.name
}
