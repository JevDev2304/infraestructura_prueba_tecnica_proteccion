variable "aws_region" {
  description = "Región AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Nombre de la aplicación (usado como prefijo en todos los recursos)"
  type        = string
  default     = "prueba-tecnica"
}

variable "db_username" {
  description = "Usuario administrador de la base de datos PostgreSQL"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña del usuario administrador de PostgreSQL (min 8 caracteres)"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Tag de la imagen Docker en ECR a desplegar (ej: latest, v1.0.0, sha-abc123)"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Puerto que expone el contenedor de la aplicación"
  type        = number
  default     = 8080
}

variable "rds_publicly_accessible" {
  description = "Hace la RDS accesible desde internet. true para pruebas con Railway, false para producción (solo ECS)"
  type        = bool
  default     = false
}

variable "ses_from_email" {
  description = "Dirección de correo verificada en SES usada como remitente"
  type        = string
  default     = "noreply@juanespruebastecnicascolombia.com"
}
