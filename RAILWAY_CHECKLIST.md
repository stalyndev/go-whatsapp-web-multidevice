# ✅ Checklist para Despliegue en Railway

## Archivos Creados/Modificados

- ✅ `Dockerfile` - Dockerfile en la raíz para Railway
- ✅ `railway.toml` - Configuración de Railway
- ✅ `.railwayignore` - Archivos a ignorar en el despliegue
- ✅ `RAILWAY_DEPLOY.md` - Guía completa de despliegue
- ✅ `src/cmd/root.go` - Modificado para leer variable `PORT` de Railway

## Configuración Necesaria en Railway

### 1. Variables de Entorno Mínimas

No hay variables obligatorias, pero se recomienda:

```bash
APP_BASIC_AUTH=usuario:contraseña
```

### 2. Volumen Persistente (CRÍTICO)

**Debes crear volúmenes para:**
- `/app/storages` - Sesiones de WhatsApp y base de datos
- `/app/statics` - QR codes, medios, archivos temporales

**Sin estos volúmenes, perderás la sesión de WhatsApp en cada reinicio.**

### 3. Puerto

✅ **Ya configurado automáticamente** - El código lee `PORT` de Railway

## Pasos Rápidos

1. **Conectar repositorio a Railway**
   - New Project → Deploy from GitHub repo
   - Seleccionar tu repositorio

2. **Agregar volúmenes**
   - Settings → Volumes → Add Volume
   - Montar `/app/storages` y `/app/statics`

3. **Configurar variables de entorno** (opcional pero recomendado)
   - Settings → Variables
   - Agregar `APP_BASIC_AUTH=usuario:contraseña`

4. **Desplegar**
   - Railway desplegará automáticamente
   - O hacer clic en "Deploy"

## Verificación

Una vez desplegado:
- ✅ Abre la URL proporcionada por Railway
- ✅ Deberías ver la página de inicio
- ✅ Ve a `/app/login` para iniciar sesión con WhatsApp

## Notas Importantes

⚠️ **Almacenamiento**: Railway ofrece almacenamiento persistente, pero es limitado en el plan gratuito. Considera usar un servicio de almacenamiento externo (S3, etc.) para producción.

⚠️ **Base de datos**: Por defecto usa SQLite. Para producción, considera usar PostgreSQL de Railway.

⚠️ **Sesiones**: Las sesiones de WhatsApp se guardan en `/app/storages`. Si el volumen no está montado, perderás la sesión en cada reinicio.

## Recursos

- [Guía Completa](./RAILWAY_DEPLOY.md)
- [Documentación Railway](https://docs.railway.app)
- [README del Proyecto](./readme.md)

