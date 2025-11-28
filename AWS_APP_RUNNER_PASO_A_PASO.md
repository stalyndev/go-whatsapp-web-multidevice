# 🚀 Guía Paso a Paso: Desplegar en AWS App Runner desde GitHub

## 📍 PASO 1: En la Pantalla Actual de App Runner

### En la sección "Origen" (Origin):

1. ✅ **Selecciona**: **"Repositorio de código fuente"** (Source code repository)
   - NO selecciones "Registro de contenedor" (esa opción es para imágenes ya construidas)

2. ✅ En **"Proveedor"** (Provider):
   - Selecciona **"GitHub"** (o el proveedor que uses)

3. 🔐 **Si es la primera vez**, verás un botón para conectar GitHub:
   - Haz clic en **"Añadir nuevo"** o **"Connect to GitHub"**
   - Te redirigirá a GitHub para autorizar AWS App Runner
   - Autoriza el acceso
   - Vuelve a App Runner

### Configuración de Repositorio:

- **Repositorio**: Selecciona `go-whatsapp-web-multidevice` (o el nombre de tu repo en GitHub)
- **Rama**: Selecciona `main` o `master` (la rama que quieres desplegar)
- **Desencadenador de implementación**: 
  - ✅ Selecciona **"Automático"** (recomendado) - Se actualizará automáticamente con cada push
  - O **"Manual"** si prefieres desplegar manualmente

### Haz clic en **"Siguiente"** (Next)

---

## 📍 PASO 2: Configuración de Construcción

App Runner detectará automáticamente tu `Dockerfile` en la raíz del repositorio.

### Opción Recomendada: **"Usar un archivo de configuración"** (Use a configuration file)

- Déjalo como está (detectará automáticamente el Dockerfile)

### O si prefieres configuración personalizada:

- **Dockerfile**: `Dockerfile`
- **Puerto**: `8080`
- **Build command**: (déjalo vacío)
- **Start command**: (déjalo vacío)

### Haz clic en **"Siguiente"** (Next)

---

## 📍 PASO 3: Configuración del Servicio

### 3.1. Información General:

- **Nombre del servicio**: `go-whatsapp-web` (o el nombre que prefieras)
- **Puerto**: `8080`
- **CPU**: `0.5 vCPU` (mínimo)
- **Memoria**: `1 GB` (mínimo)

### 3.2. Health Check:

- **Health check path**: `/`
- **Interval**: `20` segundos (puedes dejarlo por defecto)
- **Timeout**: `5` segundos (puedes dejarlo por defecto)

### 3.3. Variables de Entorno:

Haz clic en **"Agregar variable"** o **"Add environment variable"** y agrega estas:

| Nombre | Valor |
|--------|-------|
| `APP_PORT` | `8080` |
| `APP_BASIC_AUTH` | `usuario:contraseña` (cambia por tus credenciales) |
| `APP_DEBUG` | `false` |
| `APP_OS` | `Chrome` |
| `WHATSAPP_AUTO_MARK_READ` | `false` |
| `WHATSAPP_AUTO_DOWNLOAD_MEDIA` | `true` |
| `WHATSAPP_ACCOUNT_VALIDATION` | `true` |

**⚠️ IMPORTANTE**: Si planeas usar PostgreSQL (recomendado), agrega también:

| Nombre | Valor |
|--------|-------|
| `DB_URI` | `postgres://usuario:contraseña@tu-rds-endpoint.region.rds.amazonaws.com:5432/whatsappdb` |

*(Más abajo te explico cómo crear RDS si lo necesitas)*

### 3.4. Configuración de Escalado:

- **Cantidad mínima de instancias**: `1`
- **Cantidad máxima de instancias**: `3` (ajusta según necesidad)

### Haz clic en **"Siguiente"** (Next)

---

## 📍 PASO 4: Revisar y Crear

1. **Revisa toda la configuración**
2. Si todo está bien, haz clic en **"Crear e implementar"** (Create & deploy)
3. ⏳ **Espera 5-10 minutos** mientras App Runner:
   - Clona tu repositorio
   - Construye la imagen Docker
   - Despliega el servicio

---

## ✅ Después del Despliegue

Una vez completado, verás:

- ✅ **URL del servicio**: Algo como `https://xxxxx.us-east-1.awsapprunner.com`
- ✅ Estado: **"Running"** (En ejecución)

### Para probar:

1. Abre la URL en tu navegador
2. Deberías ver la página de inicio de la aplicación
3. Ve a `/app/login` para iniciar sesión con WhatsApp

---

## ⚠️ IMPORTANTE: Almacenamiento Persistente

### Problema:

App Runner con repositorio de GitHub **NO soporta volúmenes EFS** directamente.

### Solución Recomendada: **RDS PostgreSQL**

Para que las sesiones de WhatsApp se guarden permanentemente:

#### Paso A: Crear RDS PostgreSQL

1. Ve a AWS RDS Console
2. **Crear base de datos** → Selecciona **PostgreSQL**
3. Configuración:
   - **Máquina de base de datos**: `db.t3.micro` (free tier) o mayor
   - **Nombre de la base de datos**: `whatsappdb`
   - **Usuario**: `whatsapp` (o el que prefieras)
   - **Contraseña**: Crea una contraseña segura y **guárdala**
   - **Públicamente accesible**: ✅ **Sí** (para que App Runner pueda conectarse)
   - **VPC**: Deja la por defecto o selecciona una
   - **Security Group**: Asegúrate de que permita conexiones desde App Runner

4. Haz clic en **"Crear base de datos"**
5. Espera 5-10 minutos a que se cree

#### Paso B: Obtener Endpoint

1. Una vez creada, ve a la base de datos en RDS
2. Copia el **"Endpoint"**: Algo como `whatsapp-db.xxxxx.us-east-1.rds.amazonaws.com`

#### Paso C: Actualizar Variables de Entorno en App Runner

1. Ve a tu servicio en App Runner
2. **Settings** → **Configuration** → **Environment variables**
3. Edita o agrega la variable:

```
DB_URI=postgres://whatsapp:TU_CONTRASEÑA@whatsapp-db.xxxxx.us-east-1.rds.amazonaws.com:5432/whatsappdb
```

4. Haz clic en **"Save"**
5. App Runner reiniciará automáticamente con la nueva configuración

---

## 🔄 Actualizaciones Futuras

Si seleccionaste **"Automático"** en el desencadenador:

- Cada vez que hagas `git push` a la rama configurada
- App Runner detectará el cambio
- Construirá una nueva imagen
- Desplegará automáticamente

Puedes ver el progreso en la pestaña **"Deployments"** del servicio.

---

## 🆘 Problemas Comunes

### Error: "Build failed"

**Causas posibles:**
- El `Dockerfile` no está en la raíz del repositorio
- El directorio `src/` no existe

**Solución:**
- Verifica que el Dockerfile esté en la raíz (mismo nivel que `src/`)
- Revisa los logs en CloudWatch para más detalles

### Error: "Service failed to start"

**Causas posibles:**
- El puerto no coincide
- El health check falla

**Solución:**
- Verifica que `APP_PORT=8080` esté configurado
- Verifica que el path `/` responda correctamente
- Revisa los logs del servicio

### La sesión se pierde al reiniciar

**Causa:**
- Sin almacenamiento persistente, las sesiones se almacenan en el sistema de archivos temporal

**Solución:**
- Configura RDS PostgreSQL (ver arriba)
- O usa ECR con EFS (más complejo)

---

## 📝 Checklist Rápido

Antes de crear el servicio, asegúrate de:

- [ ] El `Dockerfile` está en la raíz del repositorio
- [ ] El directorio `src/` existe en GitHub
- [ ] Has decidido si usar RDS PostgreSQL o no
- [ ] Tienes las credenciales listas para las variables de entorno
- [ ] GitHub está autorizado en AWS App Runner

---

## 🎯 Resumen de Pasos

1. ✅ Selecciona **"Repositorio de código fuente"** → GitHub
2. ✅ Autoriza GitHub si es necesario
3. ✅ Selecciona tu repositorio y rama
4. ✅ Selecciona **"Automático"** para despliegue
5. ✅ Deja la configuración de build por defecto
6. ✅ Configura variables de entorno
7. ✅ Revisa y crea
8. ✅ Configura RDS PostgreSQL después (opcional pero recomendado)

---

¿Necesitas ayuda con algún paso específico? ¡Dime en qué paso estás!

