apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: platform-monitoring-dashboard
  title: Platform Monitoring Dashboard
  description: |
    Unified dashboard for accessing all platform monitoring and management tools.
    This component provides direct access to Prometheus, Grafana, ArgoCD, and Kubernetes resources.
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - monitoring
    - dashboard
    - platform
  links:
    - url: http://prometheus.kind.local
      title: Prometheus Monitoring
      icon: monitoring
    - url: http://grafana.kind.local
      title: Grafana Dashboards
      icon: dashboard
    - url: http://argocd.kind.local
      title: ArgoCD GitOps
      icon: deployment
    - url: http://alertmanager.kind.local
      title: AlertManager
      icon: alert
spec:
  type: dashboard
  lifecycle: production
  owner: platform-engineering
  system: monitoring
