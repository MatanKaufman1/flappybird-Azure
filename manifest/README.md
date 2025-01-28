# Kubernetes Application Deployment

This repository contains Kubernetes manifests and Helm charts for deploying a containerized application along with its supporting infrastructure.

## Project Overview

The project consists of a FloppyBird application deployment with MongoDB backend, integrated with various DevOps tools and services including ArgoCD, Vault, and Grafana. The application is deployed using Helm charts and managed through GitOps practices.

## Repository Structure

```
.
├── application/              # Main application Helm chart
│   ├── Chart.lock
│   ├── charts/               # Dependencies
│   ├── templates/            # Kubernetes manifests
│   └── values.yaml           # Configuration values
└── services/                 # Supporting services
    ├── argocd/               # ArgoCD configuration
    ├── argocd-vault-plugin/  # Vault integration
    └── grafana-ingress.yaml
```

## Prerequisites

### System Requirements

- Kubernetes cluster
- Helm v3
- ArgoCD installed on the cluster
- HashiCorp Vault
- Nginx Ingress Controller
- Access to Nexus registry (nexus.hdo3.local)

### Network Requirements

- Connection to local network: 10.4.0.0/24
- Nginx Reverse Proxy (10.4.0.9) for DNS resolution of all `.hdo3.local` domains

### DNS Resolution Requirements

1. Cluster-level services (requiring ingress objects and nginx ingress controller):
   - grafana.hdo3.local
   - argocd.hdo3.local
   - app.hdo3.local
   Note: Grafana and ArgoCD ingress configurations are in the repository, while the application ingress is defined in the Helm chart.

2. External services:
   - nexus.hdo3.local (Container registry access)
   - git.hdo3.local (Local Git repository)
   - jenkins.hdo3.local (Jenkins CI Server)
   - vault.hdo3.local (Secret Manager)
   - sonar.hdo3.local (Static Code analysis)

### Image Registry

- Container images should be available through nexus.hdo3.local
- Main application image: nexus.hdo3.local/flappybird-production

## Infrastructure Components

### Core Services

- **GitLab**: Version control and CI/CD (accessible at git.hdo3.local)
- **Jenkins**: CI/CD pipeline execution (jenkins.hdo3.local)
- **Nexus**: Artifact repository (nexus.hdo3.local)
- **SonarQube**: Code quality analysis (sonar.hdo3.local)
- **Vault**: Secrets management (vault.hdo3.local)
- **ArgoCD**: GitOps deployment tool (argocd.hdo3.local)
- **Grafana**: Monitoring and visualization (grafana.hdo3.local)

### Application Components

- **Application**: FloppyBird game (app.hdo3.local)
- **Database**: MongoDB (Bitnami Helm chart)
- **Ingress**: Nginx Ingress Controller

## Configuration

### MongoDB

MongoDB is deployed using the Bitnami Helm chart with the following configuration:

- Standalone architecture
- Persistent storage using local-storage StorageClass
- Metrics enabled with ServiceMonitor
- Authentication enabled using Kubernetes secrets

### Application Deployment

The main application is configured with:

- Image: `nexus.hdo3.local/flappybird-production:{tag}`
- Namespace: `floopyfloopy`
- MongoDB credentials stored in Kubernetes secrets
- Ingress configured with host `app.hdo3.local`

## Installation

1. Create the namespace:

   ```bash
   kubectl create namespace floopyfloopy
   ```

2. Configure Vault credentials and install Argocd-vault-plugin:

   ```bash
   kubectl apply -k services/argocd-vault-plugin/
   ```

3. Deploy the application using ArgoCD:

   ```bash
   kubectl apply -f services/argocd/application.yaml
   ```

## Security

- TLS enabled for all services (TLS 1.2 and 1.3) - SSL termination on NGINX
- Secure communication between services
- Secrets managed through HashiCorp Vault
- Image pull secrets required for Nexus registry access

## Monitoring

- MongoDB metrics enabled with ServiceMonitor
- Grafana dashboards available at grafana.hdo3.local
- Application metrics collection configured
- Loki readme -[Loki](Loki.md)

## Network Architecture

All services are exposed through Nginx reverse proxy with SSL termination:

- HTTP traffic (80) redirected to HTTPS (443)
- Each service has its own subdomain
- Internal communication through `goofy-network` Docker network

## Troubleshooting

Common issues and solutions:

1. Image pull errors:
   - Verify Nexus pull secrets are configured
   - Check Nexus registry availability

2. MongoDB connection issues:
   - Verify MongoDB secrets are properly configured
   - Check MongoDB service status

3. ArgoCD synchronization failures:
   - Check Vault plugin configuration
   - Verify repository credentials
