# Deploy — Prueba Técnica Protección

## Prerequisitos

- AWS CLI configurado (`aws configure`)
- Terraform instalado
- Docker con soporte `buildx`
- Acceso a GoDaddy para agregar un registro DNS

---

## Levantar la infraestructura

### 1. Aplicar Terraform

```bash
cd infraestructura_prueba_tecnica_proteccion

terraform apply \
  -var="jwt_secret=<secreto-minimo-32-caracteres>" \
  -var="app_password=<contrasena-para-obtener-token>"
```

Terraform crea todo: VPC, ECS, RDS, ALB, ACM, SSM, IAM.

Al terminar te muestra:
```
alb_dns_name = "prueba-tecnica-alb-XXXXXXX.us-east-1.elb.amazonaws.com"
ecr_repository_url = "XXXXXXX.dkr.ecr.us-east-1.amazonaws.com/prueba-tecnica"
```

### 2. Validar el certificado HTTPS en GoDaddy

Terraform se queda esperando en `aws_acm_certificate_validation`. Abre otra terminal y obtén los registros DNS:

```bash
aws acm list-certificates --query 'CertificateSummaryList[?DomainName==`www.juanespruebastecnicascolombia.com`].CertificateArn' --output text
```

Con el ARN:
```bash
aws acm describe-certificate --certificate-arn <ARN> \
  --query 'Certificate.DomainValidationOptions[0].{Name:ResourceRecord.Name,Value:ResourceRecord.Value}' \
  --output json
```

Agrega ese CNAME en GoDaddy → DNS Management. En 2-5 minutos Terraform detecta la validación y continúa.

### 3. Buildear y pushear la imagen Docker

```bash
cd back

# Login ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  XXXXXXX.dkr.ecr.us-east-1.amazonaws.com

# Build para linux/amd64 (requerido para ECS Fargate)
docker buildx build --platform linux/amd64 \
  -t XXXXXXX.dkr.ecr.us-east-1.amazonaws.com/prueba-tecnica:latest \
  --push .
```

> **Importante:** siempre usar `--platform linux/amd64`. Sin esto la imagen se buildea para arm64 (Apple Silicon) y el contenedor crashea en ECS con `exec format error`.

### 4. Forzar deploy en ECS

```bash
aws ecs update-service \
  --cluster prueba-tecnica-cluster \
  --service prueba-tecnica-service \
  --force-new-deployment
```

Espera ~2 minutos y verifica:
```bash
aws ecs describe-services \
  --cluster prueba-tecnica-cluster \
  --services prueba-tecnica-service \
  --query 'services[0].{running:runningCount,pending:pendingCount}'
```

---

## Verificar que todo funciona

```bash
# Health check
curl https://www.juanespruebastecnicascolombia.com/actuator/health

# Obtener token JWT
curl -X POST https://www.juanespruebastecnicascolombia.com/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{"password":"<app_password>"}'

# Llamar endpoint protegido
curl -X POST https://www.juanespruebastecnicascolombia.com/api/sum \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"a":10,"b":20,"email":"tu@email.com"}'

# Swagger
open https://www.juanespruebastecnicascolombia.com/swagger-ui.html
```

---

## Apagar (para no cobrar)

```bash
cd infraestructura_prueba_tecnica_proteccion

terraform destroy \
  -var="jwt_secret=cualquier-valor" \
  -var="app_password=cualquier-valor"
```

Si falla por el ECR con imágenes:
```bash
aws ecr delete-repository --repository-name prueba-tecnica --force
terraform destroy -var="jwt_secret=x" -var="app_password=x"
```

> El certificado ACM no cobra si no hay un listener activo. Al hacer destroy se elimina todo.

---

## Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| `exec format error` en ECS | Imagen buildeada para arm64 | Rebuildar con `--platform linux/amd64` |
| `AccessDeniedException` SSM | Execution Role sin permisos | `terraform apply` sincroniza los roles |
| Contenedor unhealthy | App no arrancó | Revisar CloudWatch Logs → `/ecs/prueba-tecnica` |
| HTTPS no funciona | CNAME de validación no agregado | Verificar en GoDaddy y esperar propagación |
| 403 en endpoints | Falta el header `Authorization: Bearer <token>` | Obtener token primero en `/api/auth/token` |
