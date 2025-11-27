# Guía de Despliegue en Railway

Esta guía te ayudará a desplegar tu aplicación Go WhatsApp Web Multidevice en Railway.

## Requisitos Previos

1. Cuenta en [Railway](https://railway.app)
2. Repositorio Git (GitHub, GitLab, o Bitbucket)
3. Proyecto conectado a Railway

## Pasos para Desplegar

### 1. Conectar el Repositorio

1. Ve a tu dashboard de Railway
2. Haz clic en "New Project"
3. Selecciona "Deploy from GitHub repo" (o tu proveedor Git)
4. Selecciona el repositorio `go-whatsapp-web-multidevice`

### 2. Configurar Variables de Entorno

Railway detectará automáticamente el Dockerfile. Ahora necesitas configurar las variables de entorno:

#### Variables Requeridas (Mínimas)

**Nota**: El código ahora lee automáticamente la variable `PORT` de Railway si `APP_PORT` no está definida. No necesitas configurar nada adicional para el puerto.

Si quieres usar un puerto específico:
```bash
APP_PORT=3000
```

O simplemente deja que Railway asigne el puerto automáticamente (recomendado).

#### Variables Opcionales Recomendadas

```bash
# Autenticación
APP_BASIC_AUTH=usuario:contraseña,usuario2:contraseña2

# Configuración de la aplicación
APP_DEBUG=false
APP_OS=Chrome
APP_BASE_PATH=  # Dejar vacío si no usas subpath

# Base de datos (opcional, por defecto usa SQLite)
# Si quieres usar PostgreSQL de Railway:
# DB_URI=postgres://user:pass@host:5432/dbname

# WhatsApp
WHATSAPP_AUTO_REPLY=  # Mensaje de auto-respuesta
WHATSAPP_AUTO_MARK_READ=false
WHATSAPP_AUTO_DOWNLOAD_MEDIA=true
WHATSAPP_WEBHOOK=  # URL de webhook (opcional)
WHATSAPP_WEBHOOK_SECRET=secret  # Cambiar por un secreto seguro
WHATSAPP_ACCOUNT_VALIDATION=true

# Proxy (si usas un reverse proxy)
APP_TRUSTED_PROXIES=0.0.0.0/0
```

### 3. Configurar Volumen Persistente

**IMPORTANTE**: Necesitas un volumen persistente para almacenar:
- Sesiones de WhatsApp (`storages/`)
- Códigos QR (`statics/qrcode/`)
- Medios descargados (`statics/media/`)
- Archivos a enviar (`statics/senditems/`)

1. En Railway, ve a tu servicio
2. Haz clic en "Settings"
3. En "Volumes", haz clic en "Add Volume"
4. Monta el volumen en: `/app/storages` y `/app/statics`

### 4. Configurar el Puerto

Railway asigna automáticamente el puerto a través de la variable `PORT`. El código ahora lee automáticamente esta variable si `APP_PORT` no está definida, por lo que **no necesitas configurar nada adicional**.

Si necesitas usar un puerto específico, puedes configurar:
```bash
APP_PORT=3000
```

Pero Railway recomienda dejar que asigne el puerto automáticamente.

### 5. Desplegar

Railway desplegará automáticamente cuando:
- Haces push a la rama principal
- Cambias variables de entorno
- Haces un deploy manual

## Configuración Avanzada

### Usar PostgreSQL de Railway

1. En Railway, agrega un servicio PostgreSQL
2. Railway te dará la variable `DATABASE_URL`
3. Configura en variables de entorno:
   ```bash
   DB_URI=${{Postgres.DATABASE_URL}}
   ```

### Configurar Webhook

Si quieres recibir eventos de WhatsApp en otro servicio:

```bash
WHATSAPP_WEBHOOK=https://tu-servicio.com/webhook
WHATSAPP_WEBHOOK_SECRET=tu-secreto-super-seguro
```

### Subpath Deployment

Si quieres desplegar bajo un subpath (ej: `https://tudominio.com/whatsapp`):

```bash
APP_BASE_PATH=/whatsapp
```

## Verificación Post-Despliegue

1. Una vez desplegado, Railway te dará una URL (ej: `https://tu-app.railway.app`)
2. Abre la URL en tu navegador
3. Deberías ver la página de inicio de la aplicación
4. Ve a `/app/login` para iniciar sesión con WhatsApp

## Solución de Problemas

### El servicio no inicia

- Verifica que todas las variables de entorno estén configuradas correctamente
- Revisa los logs en Railway: `View Logs`
- Asegúrate de que el volumen esté montado correctamente

### No se guardan las sesiones

- Verifica que el volumen esté montado en `/app/storages`
- Asegúrate de que el volumen tenga permisos de escritura

### Error de conexión a WhatsApp

- Verifica que el servicio esté accesible públicamente
- Railway asigna una URL pública automáticamente
- Si usas un dominio personalizado, configúralo en Railway Settings

## Recursos Adicionales

- [Documentación de Railway](https://docs.railway.app)
- [Documentación del Proyecto](./readme.md)
- [API OpenAPI](./docs/openapi.yaml)

