# Guía de Despliegue en AWS App Runner desde GitHub

Esta guía te ayudará a desplegar tu aplicación Go WhatsApp Web Multidevice en AWS App Runner directamente desde GitHub.

## 🎯 Opciones de Despliegue

Tienes **dos opciones principales**:

### Opción A: Repositorio de Código Fuente (GitHub) ⭐ Recomendado
- App Runner construye la imagen automáticamente desde tu Dockerfile
- Despliegue automático cuando haces push a GitHub
- Más simple para empezar

### Opción B: Container Registry (ECR) 
- Tú construyes y subes la imagen manualmente
- Más control sobre el proceso de construcción
- Requiere configuración adicional (GitHub Actions o scripts)

---

## 🚀 Opción A: Desplegar desde GitHub (Repositorio de Código Fuente)

### Paso 1: Preparar el Repositorio GitHub

#### 1.1. Asegúrate de tener estos archivos en la raíz del repositorio:

- ✅ `Dockerfile` (ya lo tienes)
- ✅ `src/` (directorio con el código)
- ✅ `.dockerignore` (opcional, pero recomendado)

Si no tienes `.dockerignore`, créalo:

```bash
# .dockerignore
.git
.gitignore
README.md
*.md
.vscode
.idea
gallery/
docs/
aws/
RAILWAY_*.md
```

#### 1.2. Verifica que el Dockerfile esté en la raíz:

Tu `Dockerfile` debe estar en la raíz del repositorio, no en `src/`.

### Paso 2: Conectar GitHub con AWS App Runner

#### 2.1. En la consola de AWS App Runner:

1. Haz clic en **"Create service"**
2. En **"Origen"** (Origin):
   - ✅ Selecciona **"Repositorio de código fuente"** (Source code repository)
   - ✅ En **"Proveedor"** (Provider), selecciona **GitHub** (o el que uses)
   - Si es la primera vez, te pedirá autorizar AWS para acceder a GitHub
     - Haz clic en **"Añadir nuevo"** o **"Connect to GitHub"**
     - Autoriza AWS App Runner en GitHub
     - Selecciona tu organización/repositorio

#### 2.2. Seleccionar Repositorio y Rama:

- **Repositorio**: Selecciona `go-whatsapp-web-multidevice` (o el nombre de tu repo)
- **Rama**: `main` o `master` (la rama que quieres desplegar)
- **Tipo de implementación**: Selecciona **"Automático"** para que se actualice con cada push

### Paso 3: Configurar la Construcción

#### 3.1. Configuración de Build:

App Runner detectará automáticamente tu `Dockerfile`. Configura:

- **Configuración**: Selecciona **"Usar un archivo de configuración"** (Use a configuration file)
- **Nombre del archivo de configuración**: Deja en blanco (usa Dockerfile por defecto)

O selecciona **"Usar configuración personalizada"** (Use custom configuration) y especifica:

- **Dockerfile**: `Dockerfile` (o la ruta si está en otro lugar)
- **Puerto**: `8080`
- **Build command**: (déjalo vacío, Dockerfile ya tiene las instrucciones)
- **Start command**: (déjalo vacío, Dockerfile ya tiene CMD)

### Paso 4: Configurar Variables de Entorno

En la sección **"Variables de entorno"**, agrega:

```bash
APP_PORT=8080
APP_BASIC_AUTH=usuario:contraseña
APP_DEBUG=false
APP_OS=Chrome
WHATSAPP_AUTO_MARK_READ=false
WHATSAPP_AUTO_DOWNLOAD_MEDIA=true
WHATSAPP_ACCOUNT_VALIDATION=true
```

**⚠️ IMPORTANTE**: Agrega estas variables en cada despliegue manual o configura un archivo de configuración.

### Paso 5: Configurar el Servicio

#### 5.1. Configuración General:

- **Nombre del servicio**: `go-whatsapp-web` (o el que prefieras)
- **Puerto**: `8080`
- **Health check path**: `/` (debe devolver 200 OK)

#### 5.2. Configuración de Escalado:

- **Cantidad mínima de instancias**: `1`
- **Cantidad máxima de instancias**: `3` (ajusta según necesidad)
- **Tamaño de CPU/Memoria**: `0.5 vCPU / 1 GB` (mínimo recomendado)

#### 5.3. ⚠️ ALMACENAMIENTO PERSISTENTE:

**IMPORTANTE**: App Runner **NO soporta volúmenes EFS de forma nativa** para repositorios de código fuente.

Tienes **dos opciones**:

**Opción 1: Usar Container Registry (ECR) con EFS** (Recomendado para producción)
- Requiere construir la imagen manualmente y usar ECR
- Ver Opción B más abajo

**Opción 2: Usar S3 para almacenar sesiones** (Requiere modificar código)
- Modificar el código para guardar/recuperar sesiones desde S3
- Más complejo pero funciona con App Runner

**Opción 3: Usar PostgreSQL en RDS** (Recomendado)
- Para la base de datos principal, usa RDS PostgreSQL
- Las sesiones de WhatsApp pueden almacenarse en RDS

### Paso 6: Revisar y Crear

1. Revisa la configuración
2. Haz clic en **"Crear e implementar"** (Create & deploy)
3. Espera a que App Runner construya y despliegue (5-10 minutos)

---

## 🔧 Opción B: Desplegar desde ECR (Container Registry)

Si necesitas almacenamiento persistente con EFS, usa esta opción:

### Paso 1: Construir y Subir Imagen a ECR

Tienes dos formas:

#### Opción B1: Manual (Usando Script)

```bash
# 1. Editar el script con tus valores
vim aws/deploy-apprunner.sh

# 2. Ejecutar
chmod +x aws/deploy-apprunner.sh
./aws/deploy-apprunner.sh
```

#### Opción B2: Automático con GitHub Actions

Crea `.github/workflows/deploy-aws.yml`:

```yaml
name: Deploy to AWS App Runner

on:
  push:
    branches: [ main ]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: go-whatsapp-web

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build, tag, and push image to Amazon ECR
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: latest
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

    - name: Update App Runner Service
      env:
        SERVICE_ARN: ${{ secrets.AWS_APP_RUNNER_SERVICE_ARN }}
      run: |
        aws apprunner start-deployment --service-arn $SERVICE_ARN --region ${{ env.AWS_REGION }}
```

**Configurar Secrets en GitHub:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_APP_RUNNER_SERVICE_ARN` (lo obtienes después de crear el servicio)

### Paso 2: Crear Servicio en App Runner desde ECR

1. En App Runner, selecciona **"Container registry"** (Registro de contenedor)
2. Selecciona **"Amazon ECR"**
3. Ingresa la URI de la imagen: `123456789012.dkr.ecr.us-east-1.amazonaws.com/go-whatsapp-web:latest`
4. Configura las variables de entorno (igual que Opción A)
5. **Configurar EFS** (si lo necesitas):
   - En configuración avanzada, agrega almacenamiento EFS
   - Monta `/app/storages` y `/app/statics`

---

## 📋 Configuración de Variables de Entorno

### Variables Mínimas Requeridas:

```bash
APP_PORT=8080
```

### Variables Recomendadas:

```bash
# Autenticación
APP_BASIC_AUTH=usuario:contraseña

# Configuración
APP_DEBUG=false
APP_OS=Chrome
APP_BASE_PATH=

# Base de datos (usa RDS PostgreSQL para producción)
DB_URI=postgres://usuario:contraseña@tu-rds-endpoint.region.rds.amazonaws.com:5432/whatsappdb

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

## 🔐 Configurar RDS PostgreSQL (Recomendado para Producción)

### Paso 1: Crear Base de Datos RDS

1. Ve a AWS RDS Console
2. Crear base de datos → PostgreSQL
3. Configuración:
   - **Máquina de base de datos**: `db.t3.micro` (free tier) o mayor
   - **Nombre de la base de datos**: `whatsappdb`
   - **Credenciales**: Guarda usuario y contraseña
   - **VPC**: La misma que App Runner (o accesible desde App Runner)
   - **Públicamente accesible**: Sí (o configura VPC peering)

### Paso 2: Obtener Endpoint

Después de crear, copia el endpoint de conexión:
```
tu-db.xxxxx.us-east-1.rds.amazonaws.com
```

### Paso 3: Configurar Variable de Entorno

En App Runner, agrega:

```bash
DB_URI=postgres://usuario:contraseña@tu-db.xxxxx.us-east-1.rds.amazonaws.com:5432/whatsappdb
```

---

## 🗄️ Configurar Almacenamiento Persistente

### Opción 1: Usar RDS PostgreSQL (Recomendado)

La base de datos principal (sesiones de WhatsApp) puede usar PostgreSQL.

**Ventajas:**
- ✅ Alta disponibilidad
- ✅ Backups automáticos
- ✅ Escalable
- ✅ Funciona con App Runner

**Configuración:**
```bash
DB_URI=postgres://user:pass@rds-endpoint:5432/whatsappdb
```

### Opción 2: Usar EFS (Solo con Container Registry/ECR)

Si usas ECR, puedes montar EFS:

1. Crear EFS en AWS Console
2. En App Runner, configuración avanzada → Storage
3. Agrega montaje:
   - **Source**: Tu EFS file system
   - **Mount point**: `/app/storages`
   - **Access point**: (opcional, recomendado)

### Opción 3: Usar S3 (Requiere Modificar Código)

Modificar el código para guardar sesiones en S3:

1. Crear bucket S3
2. Configurar IAM role con permisos S3
3. Modificar código para usar S3 en lugar de archivos locales

---

## 🔍 Health Checks

App Runner necesita un health check. Tu aplicación ya expone `/` que devuelve 200 OK.

**Configuración recomendada:**
- **Health check path**: `/`
- **Interval**: 20 segundos
- **Timeout**: 5 segundos
- **Unhealthy threshold**: 5
- **Healthy threshold**: 1

---

## 🚀 Despliegue Automático

Si seleccionaste **"Automático"** en el desencadenador:

- Cada push a la rama configurada iniciará un nuevo despliegue
- App Runner construirá la imagen desde el Dockerfile
- Desplegará automáticamente

### Despliegue Manual

Para desplegar manualmente:

1. Ve al servicio en App Runner
2. Haz clic en **"Start deployment"**
3. Selecciona la rama o tag que quieres desplegar

---

## 📊 Monitoreo

### Logs

Los logs están disponibles en:
- CloudWatch Logs → `/aws/apprunner/go-whatsapp-web/service/...`
- O en la consola de App Runner → **Logs**

### Métricas

App Runner proporciona métricas automáticas:
- Requests
- Latency
- HTTP errors
- CPU/Memory usage

---

## ⚠️ Limitaciones de App Runner

1. **No soporta EFS nativo con repositorio de código fuente**
   - Usa RDS PostgreSQL o ECR con EFS

2. **Tiempo máximo de build**: 30 minutos
   - Tu Dockerfile debería construir en menos tiempo

3. **Tamaño máximo de imagen**: 10 GB
   - Tu imagen es pequeña (~100-200 MB), no hay problema

4. **Sin SSH directo**
   - No puedes acceder directamente a la instancia

---

## 🎯 Checklist de Despliegue

- [ ] Repositorio GitHub configurado con Dockerfile en la raíz
- [ ] GitHub autorizado en AWS App Runner
- [ ] Variables de entorno configuradas
- [ ] RDS PostgreSQL creado (recomendado)
- [ ] Health check configurado (`/`)
- [ ] Despliegue automático habilitado (opcional)
- [ ] Dominio personalizado configurado (opcional)

---

## 🆘 Troubleshooting

### Error: "Build failed"
- Verifica que el Dockerfile esté en la raíz
- Verifica que `src/` exista en el repositorio
- Revisa los logs de construcción en CloudWatch

### Error: "Service failed to start"
- Verifica que `APP_PORT` esté configurado correctamente
- Verifica que el health check path `/` responda
- Revisa los logs del servicio

### La sesión se pierde
- ⚠️ **Sin almacenamiento persistente, las sesiones se pierden al reiniciar**
- Usa RDS PostgreSQL o ECR con EFS

### Error de conexión a RDS
- Verifica que el Security Group de RDS permita conexiones desde App Runner
- Verifica que `DB_URI` esté correctamente configurado
- Verifica que el RDS esté en la misma VPC (o configurar peering)

---

## 📚 Próximos Pasos

1. **Dominio personalizado**: Configura un dominio en Route 53
2. **SSL/TLS**: App Runner lo maneja automáticamente
3. **Monitoreo avanzado**: Configura alertas en CloudWatch
4. **Backups**: Configura backups automáticos de RDS

---

## 💡 Recomendación Final

**Para empezar rápido:**
1. Usa **Opción A** (GitHub como origen)
2. Configura **RDS PostgreSQL** para la base de datos
3. Usa **despliegue automático**

**Para producción:**
1. Usa **Opción B** (ECR con EFS)
2. Configura **GitHub Actions** para CI/CD
3. Configura **monitoreo y alertas**

---

¿Necesitas ayuda con algún paso específico?

