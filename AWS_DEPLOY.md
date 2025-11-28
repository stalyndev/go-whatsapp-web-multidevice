# Guía de Despliegue en AWS

Esta guía cubre las mejores opciones para desplegar tu aplicación Go WhatsApp Web Multidevice en AWS.

## 🎯 Opciones de Despliegue en AWS

### 1. **AWS App Runner** (Recomendado - Más Fácil) ⭐
- Similar a Railway
- Despliegue automático desde contenedor Docker
- Escalado automático
- Gestión simple de variables de entorno
- **Ideal para**: Inicio rápido, desarrollo y producción pequeña/mediana

### 2. **AWS ECS (Fargate)** (Recomendado para Producción)
- Contenedores completamente gestionados
- Mayor control y flexibilidad
- Integración con otros servicios AWS
- **Ideal para**: Producción, alta disponibilidad, integración con otros servicios AWS

### 3. **AWS Elastic Beanstalk**
- Gestión simplificada de infraestructura
- Soporte nativo para aplicaciones Go
- Auto-escalado y monitoreo
- **Ideal para**: Quienes prefieren gestión de infraestructura simplificada

### 4. **AWS EC2**
- Control total sobre el servidor
- Más económico para cargas consistentes
- Requiere más configuración manual
- **Ideal para**: Control máximo, costos optimizados

---

## 🚀 Opción 1: AWS App Runner (Más Fácil)

### Requisitos Previos
- Cuenta de AWS con permisos para App Runner
- Repositorio en AWS ECR (Elastic Container Registry) o Docker Hub
- AWS CLI configurado (opcional, puedes usar la consola web)

### Pasos

#### 1. Construir y Subir la Imagen Docker

**Opción A: Usar Docker Hub (Más Fácil)**

```bash
# Construir la imagen
docker build -t tu-usuario/go-whatsapp-web:latest .

# Subir a Docker Hub
docker login
docker push tu-usuario/go-whatsapp-web:latest
```

**Opción B: Usar AWS ECR**

```bash
# Crear repositorio en ECR (vía consola AWS o CLI)
aws ecr create-repository --repository-name go-whatsapp-web

# Obtener URL del repositorio (ejemplo: 123456789012.dkr.ecr.us-east-1.amazonaws.com)
ECR_REPO=123456789012.dkr.ecr.us-east-1.amazonaws.com/go-whatsapp-web

# Autenticarse en ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO

# Construir y subir
docker build -t go-whatsapp-web:latest .
docker tag go-whatsapp-web:latest $ECR_REPO:latest
docker push $ECR_REPO:latest
```

#### 2. Crear Servicio en App Runner

1. Ve a la consola de AWS App Runner
2. Haz clic en "Create service"
3. Selecciona "Container registry" → Tu repositorio (ECR o Docker Hub)
4. Configura el servicio:

**Configuración Básica:**
- Service name: `go-whatsapp-web`
- Port: `8080` (App Runner asignará automáticamente)

**Variables de Entorno:**
```
APP_PORT=8080
APP_BASIC_AUTH=usuario:contraseña
APP_DEBUG=false
APP_OS=Chrome
WHATSAPP_AUTO_REPLY=
WHATSAPP_AUTO_MARK_READ=false
WHATSAPP_AUTO_DOWNLOAD_MEDIA=true
WHATSAPP_ACCOUNT_VALIDATION=true
```

**Configuración de Escalado:**
- Min: 1
- Max: 5 (ajustar según necesidad)

#### 3. ⚠️ IMPORTANTE: Almacenamiento Persistente

**App Runner NO soporta volúmenes persistentes nativos.** Tienes dos opciones:

**Opción A: Usar S3 para sesiones (Recomendado)**
- Configurar S3 bucket para almacenar sesiones
- Modificar código para guardar/recuperar sesiones desde S3
- Requiere cambios en el código

**Opción B: Usar EFS (Elastic File System) con App Runner (Recomendado)**
- Crear un sistema de archivos EFS
- Montar EFS en App Runner
- Mantener la estructura actual del código

**Configuración de EFS en App Runner:**

1. Crear EFS en AWS Console:
   - VPC: La misma que usarás en App Runner
   - Availability Zone: Múltiples zonas para alta disponibilidad
   - Encrypt data at rest: Habilitado (recomendado)

2. En App Runner, al crear el servicio:
   - Ve a "Advanced settings"
   - Agrega "Storage" → "Add storage"
   - Mount point: `/app/storages`
   - EFS file system: Selecciona el EFS creado
   - Mount point: `/app/statics` (segunda montura si necesitas)

**⚠️ LIMITACIÓN**: App Runner con EFS requiere configuración de VPC, lo cual agrega complejidad.

#### 4. Configurar Dominio Personalizado (Opcional)

En App Runner:
- Settings → Custom domains → Add domain
- Sigue las instrucciones para configurar DNS

---

## 🐳 Opción 2: AWS ECS con Fargate (Recomendado para Producción)

### Ventajas
- ✅ Soporte completo para volúmenes EFS
- ✅ Mayor control sobre la configuración
- ✅ Escalado automático avanzado
- ✅ Integración con Load Balancer
- ✅ Alta disponibilidad

### Pasos

#### 1. Crear Task Definition

Crea un archivo `task-definition.json`:

```json
{
  "family": "go-whatsapp-web",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "whatsapp-app",
      "image": "YOUR_ECR_REPO_URL:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "APP_PORT",
          "value": "8080"
        },
        {
          "name": "APP_BASIC_AUTH",
          "value": "usuario:contraseña"
        },
        {
          "name": "APP_DEBUG",
          "value": "false"
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "storages",
          "containerPath": "/app/storages",
          "readOnly": false
        },
        {
          "sourceVolume": "statics",
          "containerPath": "/app/statics",
          "readOnly": false
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/go-whatsapp-web",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "volumes": [
    {
      "name": "storages",
      "efsVolumeConfiguration": {
        "fileSystemId": "fs-xxxxxxxxx",
        "rootDirectory": "/storages",
        "transitEncryption": "ENABLED"
      }
    },
    {
      "name": "statics",
      "efsVolumeConfiguration": {
        "fileSystemId": "fs-yyyyyyyyy",
        "rootDirectory": "/statics",
        "transitEncryption": "ENABLED"
      }
    }
  ]
}
```

#### 2. Crear EFS

```bash
# Crear sistema de archivos EFS
aws efs create-file-system \
  --creation-token whatsapp-storages \
  --performance-mode generalPurpose \
  --encrypted \
  --region us-east-1

# Crear mount targets (una por cada Availability Zone)
aws efs create-mount-target \
  --file-system-id fs-xxxxxxxxx \
  --subnet-id subnet-xxxxx \
  --security-groups sg-xxxxx
```

#### 3. Crear Cluster ECS

```bash
aws ecs create-cluster --cluster-name whatsapp-cluster
```

#### 4. Registrar Task Definition

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

#### 5. Crear Servicio ECS

```bash
aws ecs create-service \
  --cluster whatsapp-cluster \
  --service-name whatsapp-service \
  --task-definition go-whatsapp-web \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}"
```

#### 6. Configurar Application Load Balancer (Recomendado)

Para alta disponibilidad y balanceo de carga:

1. Crear ALB en AWS Console
2. Crear Target Group apuntando al puerto 8080
3. Configurar Health Check: `GET /` → 200 OK
4. Actualizar el servicio ECS para usar el ALB

---

## 🌱 Opción 3: AWS Elastic Beanstalk

### Ventajes
- ✅ Gestión simplificada
- ✅ Auto-escalado y monitoreo incluido
- ✅ Despliegue fácil con CLI
- ✅ Soporte para Docker

### Pasos

#### 1. Instalar EB CLI

```bash
pip install awsebcli
```

#### 2. Crear Archivo de Configuración

Crea `.ebextensions/whatsapp.config`:

```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    APP_PORT: 8080
    APP_BASIC_AUTH: usuario:contraseña
    APP_DEBUG: false
  aws:elasticbeanstalk:environment:proxy:staticfiles:
    /static: statics
```

#### 3. Inicializar Elastic Beanstalk

```bash
eb init -p docker go-whatsapp-web --region us-east-1
```

#### 4. Crear Entorno

```bash
eb create whatsapp-env --instance-type t3.small
```

#### 5. Desplegar

```bash
eb deploy
```

**⚠️ NOTA**: Elastic Beanstalk también requiere EFS para almacenamiento persistente, similar a las otras opciones.

---

## 💻 Opción 4: AWS EC2 (Control Total)

### Pasos

#### 1. Lanzar Instancia EC2

- AMI: Amazon Linux 2023 o Ubuntu Server
- Instance Type: t3.small o superior
- Security Group: Abrir puerto 8080 (y 80/443 si usas nginx)

#### 2. Instalar Docker

```bash
# Amazon Linux
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Ubuntu
sudo apt update
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ubuntu
```

#### 3. Instalar Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 4. Clonar y Desplegar

```bash
git clone tu-repo.git
cd go-whatsapp-web-multidevice

# Crear archivo .env
cat > .env << EOF
APP_PORT=8080
APP_BASIC_AUTH=usuario:contraseña
APP_DEBUG=false
EOF

# Construir y ejecutar
docker-compose up -d --build
```

#### 5. Configurar Nginx como Reverse Proxy (Recomendado)

```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

#### 6. Configurar Almacenamiento Persistente

En EC2, el almacenamiento es persistente por defecto en la instancia. Sin embargo, para mayor seguridad, considera:
- Usar EBS volumes adicionales
- Configurar backups automáticos
- O montar EFS si necesitas compartir entre múltiples instancias

---

## 🔐 Configuración de Variables de Entorno

### Variables Requeridas (Mínimas)

```bash
APP_PORT=8080
```

### Variables Recomendadas

```bash
# Autenticación
APP_BASIC_AUTH=usuario:contraseña

# Configuración
APP_DEBUG=false
APP_OS=Chrome
APP_BASE_PATH=

# Base de datos (opcional - usar RDS PostgreSQL para producción)
DB_URI=postgres://user:pass@rds-endpoint:5432/dbname

# WhatsApp
WHATSAPP_AUTO_REPLY=
WHATSAPP_AUTO_MARK_READ=false
WHATSAPP_AUTO_DOWNLOAD_MEDIA=true
WHATSAPP_WEBHOOK=https://tu-webhook.com
WHATSAPP_WEBHOOK_SECRET=tu-secreto-seguro
WHATSAPP_ACCOUNT_VALIDATION=true

# Proxy
APP_TRUSTED_PROXIES=0.0.0.0/0
```

---

## 💾 Base de Datos en AWS

### Opción 1: SQLite (Por Defecto)
- ✅ Simple, sin configuración adicional
- ❌ No recomendado para producción
- ✅ Funciona si usas EFS/volúmenes persistentes

### Opción 2: Amazon RDS PostgreSQL (Recomendado para Producción)

```bash
# Variables de entorno
DB_URI=postgres://usuario:contraseña@tu-rds-endpoint.region.rds.amazonaws.com:5432/whatsappdb
```

**Crear RDS:**
1. Ve a AWS RDS Console
2. Crear base de datos → PostgreSQL
3. Configurar credenciales
4. Obtener endpoint de conexión
5. Actualizar variable de entorno `DB_URI`

---

## 🔍 Monitoreo y Logs

### CloudWatch Logs

Todas las opciones de AWS pueden enviar logs a CloudWatch:

```bash
# En tu aplicación, los logs ya están estructurados
# CloudWatch los capturará automáticamente
```

### Health Checks

Tu aplicación ya expone `/` como health check. Configura:
- ECS/App Runner: Health check en `/`
- ALB: Health check en `/`
- EC2: Usar nginx o elixir para health checks

---

## 📊 Comparación de Opciones

| Opción | Facilidad | Costo | Escalado | Persistencia | Recomendado Para |
|--------|-----------|-------|----------|--------------|------------------|
| App Runner | ⭐⭐⭐⭐⭐ | Medio | Automático | Con EFS | Inicio rápido |
| ECS Fargate | ⭐⭐⭐ | Medio-Alto | Automático | EFS nativo | Producción |
| Elastic Beanstalk | ⭐⭐⭐⭐ | Medio | Automático | Con EFS | Gestión simplificada |
| EC2 | ⭐⭐ | Bajo | Manual | EBS/EFS | Control total |

---

## 🎯 Recomendación Final

- **Para empezar rápido**: AWS App Runner
- **Para producción**: AWS ECS (Fargate) con EFS y ALB
- **Para costos bajos**: EC2 con EBS
- **Para simplicidad**: Elastic Beanstalk

---

## 📝 Checklist de Despliegue

- [ ] Imagen Docker construida y subida a ECR/Docker Hub
- [ ] Variables de entorno configuradas
- [ ] EFS creado (si usas App Runner, ECS, o Beanstalk)
- [ ] Security Groups configurados (puerto 8080 abierto)
- [ ] Health checks configurados
- [ ] Dominio personalizado configurado (opcional)
- [ ] RDS PostgreSQL creado (opcional, recomendado para producción)
- [ ] CloudWatch Logs configurados
- [ ] Backups configurados (EBS snapshots o EFS backups)

---

## 🆘 Troubleshooting

### La sesión se pierde al reiniciar
- ✅ Verifica que EFS/volúmenes estén montados correctamente
- ✅ Verifica permisos de escritura en `/app/storages`

### Health checks fallan
- ✅ Verifica que `APP_PORT` coincida con el puerto expuesto
- ✅ Verifica Security Groups
- ✅ Verifica logs en CloudWatch

### Alto uso de memoria
- ✅ Aumenta el tamaño de instancia/task
- ✅ Considera usar RDS PostgreSQL en lugar de SQLite

---

## 📚 Recursos Adicionales

- [AWS App Runner Docs](https://docs.aws.amazon.com/apprunner/)
- [AWS ECS Docs](https://docs.aws.amazon.com/ecs/)
- [AWS EFS Docs](https://docs.aws.amazon.com/efs/)
- [Docker Hub](https://hub.docker.com/)

