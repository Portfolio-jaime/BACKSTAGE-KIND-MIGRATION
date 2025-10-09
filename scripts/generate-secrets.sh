#!/bin/bash

# Script para generar secrets.yaml desde .env
# Usage: ./scripts/generate-secrets.sh

set -e

# Verificar que existe el archivo .env
if [[ ! -f ".env" ]]; then
    echo "Error: No se encontró el archivo .env"
    echo "Copia .env.example a .env y completa los valores"
    exit 1
fi

# Cargar variables de entorno
source .env

# Verificar que las variables críticas estén definidas
if [[ -z "$GITHUB_TOKEN" || -z "$ARGOCD_PASSWORD" || -z "$BACKEND_SECRET" ]]; then
    echo "Error: Faltan variables críticas en .env"
    echo "Asegúrate de que GITHUB_TOKEN, ARGOCD_PASSWORD y BACKEND_SECRET estén definidas"
    exit 1
fi

# Generar el archivo secrets.yaml
cat > kubernetes/secrets-generated.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: backstage-secrets
  namespace: backstage
  labels:
    app: backstage
type: Opaque
stringData:
  # PostgreSQL credentials (from existing cluster)
  POSTGRES_HOST: "${POSTGRES_HOST}"
  POSTGRES_PORT: "${POSTGRES_PORT}"
  POSTGRES_USER: "${POSTGRES_USER}"
  POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
  POSTGRES_DB: "${POSTGRES_DB}"

  # GitHub token for integrations
  GITHUB_TOKEN: "${GITHUB_TOKEN}"

  # ArgoCD credentials
  ARGOCD_USERNAME: "${ARGOCD_USERNAME}"
  ARGOCD_PASSWORD: "${ARGOCD_PASSWORD}"
  ARGOCD_AUTH_TOKEN: "${ARGOCD_AUTH_TOKEN}"

  # Backend secret key
  BACKEND_SECRET: "${BACKEND_SECRET}"

  # GitHub OAuth
  AUTH_GITHUB_CLIENT_ID: "${AUTH_GITHUB_CLIENT_ID}"
  AUTH_GITHUB_CLIENT_SECRET: "${AUTH_GITHUB_CLIENT_SECRET}"
EOF

echo "✅ Archivo secrets-generated.yaml creado exitosamente"
echo "📝 Usa 'kubectl apply -f kubernetes/secrets-generated.yaml' para deployar"