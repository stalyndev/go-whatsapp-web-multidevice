# Archivos de Configuración para AWS

Este directorio contiene archivos de configuración y scripts útiles para desplegar en AWS.

## Archivos Incluidos

### `ecs-task-definition.json`
Definición de tarea para AWS ECS (Fargate). Incluye:
- Configuración de contenedor
- Variables de entorno
- Montajes de EFS para almacenamiento persistente
- Health checks
- Configuración de logs en CloudWatch

**Antes de usar:**
1. Reemplaza `YOUR_ACCOUNT_ID` con tu ID de cuenta AWS
2. Reemplaza `YOUR_ECR_REPO_URL` con la URL de tu repositorio ECR
3. Reemplaza `fs-xxxxxxxxx` con el ID de tu sistema de archivos EFS
4. Reemplaza `fsap-xxxxxxxxx` con el ID de tu Access Point de EFS

### `ebextensions/whatsapp.config`
Configuración para AWS Elastic Beanstalk. Incluye:
- Variables de entorno
- Configuración de auto-escalado
- Health checks
- Logs en CloudWatch

### Scripts

#### `deploy-ecs.sh`
Script automatizado para desplegar en ECS. Realiza:
1. Construcción de imagen Docker
2. Autenticación en ECR
3. Subida de imagen a ECR
4. Actualización de task definition
5. Actualización del servicio ECS

**Uso:**
```bash
chmod +x aws/deploy-ecs.sh
# Edita las variables al inicio del script
./aws/deploy-ecs.sh
```

#### `deploy-apprunner.sh`
Script para construir y subir imagen a ECR para App Runner.

**Uso:**
```bash
chmod +x aws/deploy-apprunner.sh
# Edita las variables al inicio del script
./aws/deploy-apprunner.sh
```

## Requisitos Previos

### Para usar los scripts:

1. **AWS CLI instalado y configurado:**
```bash
aws configure
```

2. **Docker instalado:**
```bash
docker --version
```

3. **Permisos IAM necesarios:**
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `ecr:PutImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`
- `ecr:CreateRepository` (si el repositorio no existe)
- `ecs:RegisterTaskDefinition`
- `ecs:UpdateService`
- `ecs:DescribeServices`
- `ecs:DescribeTasks`

### Para ECS Task Definition:

1. **Roles IAM creados:**
- `ecsTaskExecutionRole` - Para ejecutar tareas ECS
- `ecsTaskRole` - Para permisos de la aplicación

2. **EFS creado y configurado:**
- Sistema de archivos EFS
- Mount targets en las subnets
- Access points (opcional pero recomendado)

3. **CloudWatch Log Group:**
```bash
aws logs create-log-group --log-group-name /ecs/go-whatsapp-web --region us-east-1
```

## Pasos para Desplegar

### Opción 1: ECS con Script Automatizado

```bash
# 1. Editar variables en deploy-ecs.sh
vim aws/deploy-ecs.sh

# 2. Crear cluster ECS (primera vez)
aws ecs create-cluster --cluster-name whatsapp-cluster --region us-east-1

# 3. Crear servicio ECS (primera vez)
# Usa la consola AWS o terraform para crear el servicio inicial

# 4. Ejecutar script
./aws/deploy-ecs.sh
```

### Opción 2: ECS Manual

```bash
# 1. Construir y subir imagen
docker build -t go-whatsapp-web:latest .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ECR_URI
docker tag go-whatsapp-web:latest YOUR_ECR_URI:latest
docker push YOUR_ECR_URI:latest

# 2. Editar task definition
vim aws/ecs-task-definition.json

# 3. Registrar task definition
aws ecs register-task-definition --cli-input-json file://aws/ecs-task-definition.json

# 4. Actualizar servicio
aws ecs update-service --cluster whatsapp-cluster --service whatsapp-service --task-definition go-whatsapp-web --force-new-deployment
```

### Opción 3: App Runner

```bash
# 1. Ejecutar script para subir imagen
./aws/deploy-apprunner.sh

# 2. Crear servicio en App Runner usando la consola AWS
# Usa la URI de la imagen proporcionada por el script
```

## Configuración de EFS

Para almacenamiento persistente, necesitas configurar EFS:

### 1. Crear EFS

```bash
# Crear sistema de archivos
EFS_ID=$(aws efs create-file-system \
  --creation-token whatsapp-storages \
  --performance-mode generalPurpose \
  --encrypted \
  --region us-east-1 \
  --query 'FileSystemId' \
  --output text)

echo "EFS ID: $EFS_ID"
```

### 2. Crear Access Points (Recomendado)

```bash
# Para storages
STORAGE_AP=$(aws efs create-access-point \
  --file-system-id $EFS_ID \
  --posix-user Uid=1000,Gid=1000 \
  --root-directory Path=/storages,CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=755} \
  --query 'AccessPointId' \
  --output text)

# Para statics
STATICS_AP=$(aws efs create-access-point \
  --file-system-id $EFS_ID \
  --posix-user Uid=1000,Gid=1000 \
  --root-directory Path=/statics,CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=755} \
  --query 'AccessPointId' \
  --output text)
```

### 3. Crear Mount Targets

Para cada subnet en tu VPC:

```bash
aws efs create-mount-target \
  --file-system-id $EFS_ID \
  --subnet-id subnet-xxxxx \
  --security-groups sg-xxxxx
```

## Troubleshooting

### Error: "CannotPullContainerError"
- Verifica que el repositorio ECR existe
- Verifica que el task role tiene permisos para ECR
- Verifica que la imagen existe en ECR

### Error: "CannotCreateLogStream"
- Crea el log group de CloudWatch:
```bash
aws logs create-log-group --log-group-name /ecs/go-whatsapp-web
```

### Error: "Mount timeout"
- Verifica que los mount targets de EFS están en la misma VPC que las tareas ECS
- Verifica los security groups permiten tráfico NFS (puerto 2049)
- Verifica que las subnets tienen rutas correctas

### La sesión se pierde
- Verifica que EFS está montado correctamente
- Verifica permisos de escritura en `/app/storages`
- Verifica que el volumen no está en modo read-only

## Recursos Adicionales

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS EFS Documentation](https://docs.aws.amazon.com/efs/)
- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [AWS Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)

