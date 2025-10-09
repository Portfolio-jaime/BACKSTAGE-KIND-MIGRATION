# 🔐 Manejo de Secretos

Este proyecto usa un sistema seguro para manejar secretos y credenciales.

## 📋 Setup Inicial

1. **Copia el archivo de ejemplo:**
   ```bash
   cp .env.example .env
   ```

2. **Completa los valores reales en `.env`:**
   - `GITHUB_TOKEN`: Token personal de GitHub con permisos de repo
   - `ARGOCD_PASSWORD`: Password de ArgoCD admin
   - `ARGOCD_AUTH_TOKEN`: Token JWT de ArgoCD
   - `BACKEND_SECRET`: Clave secreta para el backend de Backstage
   - `AUTH_GITHUB_CLIENT_*`: Credenciales OAuth de GitHub

## 🚀 Generar Secretos para Kubernetes

Para generar el archivo de secretos de Kubernetes:

```bash
./scripts/generate-secrets.sh
```

Esto creará `kubernetes/secrets-generated.yaml` con los valores reales desde tu `.env`.

## 📁 Estructura de Archivos

- `.env` - **NO se sube a git** - Contiene valores reales
- `.env.example` - **SÍ se sube a git** - Template con ejemplos
- `kubernetes/secrets.yaml` - **SÍ se sube a git** - Template para deployment
- `kubernetes/secrets-generated.yaml` - **NO se sube a git** - Archivo generado con valores reales

## 🔒 Seguridad

- El archivo `.env` está en `.gitignore` y nunca se sube al repositorio
- Los archivos generados (`*-generated.yaml`) tampoco se suben
- Solo los templates se mantienen en el repositorio

## 🛠️ Deployment

1. Asegúrate de tener tu `.env` configurado
2. Genera los secretos: `./scripts/generate-secrets.sh`
3. Aplica a Kubernetes: `kubectl apply -f kubernetes/secrets-generated.yaml`

## ⚠️ Importante

**NUNCA** subas archivos `.env` o con credenciales reales al repositorio Git.