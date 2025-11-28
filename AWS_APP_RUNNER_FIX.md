# 🔧 Solución al Error de Build en App Runner

## Problema
```
Failed to build your application source code. Reason: Failed to execute 'build' command.
```

## Solución

### Opción 1: Eliminar apprunner.yaml (Recomendado) ✅

App Runner detecta automáticamente el `Dockerfile` si está en la raíz del repositorio. **NO necesitas** `apprunner.yaml` si tienes Dockerfile.

**Pasos:**
1. Elimina o renombra `apprunner.yaml` en tu repositorio
2. Haz commit y push:
```bash
git rm apprunner.yaml
# o
git mv apprunner.yaml apprunner.yaml.bak
git commit -m "Remove apprunner.yaml to use Dockerfile directly"
git push
```

3. En App Runner, configuración de compilación:
   - Selecciona **"Configure todos los ajustes aquí"** (Configure all settings here)
   - **NO** selecciones "Usar un archivo de configuración"
   - App Runner detectará automáticamente el Dockerfile

### Opción 2: Configurar Manualmente en App Runner

Si prefieres no eliminar el archivo, en la consola de App Runner:

1. Ve a **Settings** → **Configuration** → **Build & Deploy**
2. Cambia a **"Configure all settings here"**
3. En **"Build configuration"**:
   - **Build method**: Selecciona **"Dockerfile"** o **"Use Dockerfile"**
   - **Dockerfile path**: `Dockerfile` (o déjalo en blanco si está en la raíz)
   - **Port**: `8080`
4. Guarda y redepiega

### Opción 3: Usar Runtime Go (Sin Dockerfile)

Si prefieres compilar directamente sin Dockerfile:

1. En App Runner, configuración de compilación:
   - **Runtime**: `Go 1`
   - **Build command**: `cd src && go mod download && go build -o whatsapp .`
   - **Start command**: `cd src && ./whatsapp rest`
   - **Port**: `8080`

**⚠️ NOTA**: Esta opción requiere que FFmpeg esté disponible en el runtime de App Runner, lo cual puede no estar disponible.

## ✅ Recomendación Final

**Usa la Opción 1**: Elimina `apprunner.yaml` y deja que App Runner detecte el Dockerfile automáticamente. Es la forma más simple y confiable.

## Verificación

Después de hacer los cambios:

1. Haz commit y push de los cambios
2. App Runner debería detectar automáticamente el cambio
3. O inicia un despliegue manual desde la consola
4. Revisa los logs para ver si el build es exitoso

## Logs para Debugging

Si sigue fallando, revisa los logs en:
- App Runner Console → Tu servicio → **Logs**
- Busca mensajes de error específicos sobre el build

