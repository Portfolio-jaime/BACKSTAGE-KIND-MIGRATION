# GitHub Actions Workflows

Este directorio contiene los workflows de GitHub Actions para el proyecto Backstage.

## Workflows Disponibles

### 🔄 CI/CD Pipeline (`ci-cd.yaml`)

**Propósito**: Pipeline completo de integración y despliegue continuo.

**Disparadores**:
- Push a `main` o `develop`
- Pull requests
- Despacho manual

**Jobs**:
1. **build-and-push**: Construye, prueba y publica imagen Docker
2. **deploy-to-kind**: Actualiza ArgoCD con nueva imagen (solo main)
3. **notify-update**: Instrucciones de actualización
4. **cleanup**: Limpieza de imágenes antiguas

**Características de Seguridad**:
- Escaneo de vulnerabilidades con Trivy (filesystem e imagen)
- Auditoría de dependencias NPM
- Reportes SARIF a GitHub Security tab

### ✅ PR Checks (`pr-checks.yaml`)

**Propósito**: Validaciones automáticas para pull requests.

**Disparadores**:
- PRs a `main` o `develop`

**Jobs**:
1. **lint-and-test**: Linting y pruebas
2. **build-check**: Verificación de builds
3. **helm-lint**: Validación de charts Helm
4. **docker-build-test**: Build y escaneo de imagen Docker

**Características de Seguridad**:
- Escaneo de vulnerabilidades en imágenes PR
- Auditoría de dependencias
- Falla en vulnerabilidades críticas

## Configuración de Seguridad

### Permisos Requeridos

```yaml
permissions:
  contents: write          # Para commits automáticos
  security-events: write   # Para reportes SARIF
  packages: write          # Para GitHub Packages
  pull-requests: write     # Para comentarios en PRs
```

### Secrets Requeridos

- `DOCKERHUB_USERNAME`: Usuario de Docker Hub
- `DOCKERHUB_TOKEN`: Token de acceso a Docker Hub

## Mejores Prácticas Implementadas

### ✅ Seguridad
- Escaneo continuo de vulnerabilidades
- Auditorías de dependencias
- Permisos mínimos necesarios
- Reportes automáticos a GitHub Security

### ✅ Mantenibilidad
- Código DRY (eliminación de duplicados)
- Manejo robusto de errores
- Cache inteligente
- Documentación clara

### ✅ Rendimiento
- Builds multi-plataforma (amd64/arm64)
- Cache de dependencias y Docker
- Ejecución condicional
- Paralelización de jobs

## Troubleshooting

### Problemas Comunes

**Fallo en escaneo de vulnerabilidades**:
- Verificar configuración de Trivy
- Revisar permisos de `security-events`

**Error en push a Docker Hub**:
- Verificar secrets `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN`
- Confirmar límites de rate limit

**Fallo en actualización ArgoCD**:
- Verificar configuración de Git
- Revisar permisos de repositorio

### Comandos Útiles

```bash
# Ver estado de workflows
gh workflow list

# Ver logs de workflow específico
gh run list --workflow=ci-cd.yaml

# Re-ejecutar workflow fallido
gh run rerun <run-id>
```

## Métricas y Monitoreo

- **Tiempo de ejecución**: Monitorear duración de jobs
- **Tasa de éxito**: Tracking de fallos recurrentes
- **Cobertura de seguridad**: Vulnerabilidades encontradas vs resueltas

## Próximas Mejoras

- [ ] Implementar cache para Helm
- [ ] Agregar tests de integración
- [ ] Automatizar rotación de secrets
- [ ] Implementar rollback automático
- [ ] Agregar métricas de rendimiento