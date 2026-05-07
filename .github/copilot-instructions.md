# Copilot Instructions

## Project Overview

This repository contains two Flask web applications deployed to Kubernetes using ArgoCD for GitOps continuous delivery. This is a learning project for Kubernetes and ArgoCD concepts.

## Architecture

- **argo-web**: Flask application exposed on NodePort 30080
- **k8s-web**: Flask application exposed on NodePort 30081
- **ArgoCD**: App-of-Apps pattern for managing both applications
- **Kubernetes**: Deployed to minikube with namespace isolation

## Technology Stack

- Python 3.13 with Flask framework
- UV package manager (modern replacement for pip)
- Docker multi-stage builds with `python:3.13-slim`
- Gunicorn WSGI server (port 5000 internal)
- Kubernetes manifests in `argo-templates/`
- ArgoCD for GitOps deployment

## Directory Structure

```
├── src/
│   ├── argo-web/          # First Flask application
│   │   ├── app/
│   │   │   ├── main.py    # Flask entry point
│   │   │   ├── static/    # CSS, images
│   │   │   └── templates/ # HTML templates
│   │   ├── Dockerfile
│   │   ├── wsgi.py        # Gunicorn entry point
│   │   └── gunicorn.conf.py
│   └── k8s-web/           # Second Flask application (mirror of argo-web)
├── argo-templates/        # Kubernetes manifests
│   ├── argo-web/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── k8s-web/
├── apps/                  # ArgoCD Application manifests
│   ├── argo-web.yaml
│   └── k8s-web.yaml
├── app-of-apps.yaml       # Root ArgoCD Application
├── tools/                 # Build automation scripts
│   ├── build-argo-web.ps1
│   └── build-k8s-web.ps1
└── pyproject.toml         # Python dependencies

## Key Concepts

### Docker Images
- **argoweb:v1.0**: Built from `src/argo-web/Dockerfile`
- **k8sweb:v1.0**: Built from `src/k8s-web/Dockerfile`
- Both use `imagePullPolicy: Never` for local minikube images

### Namespace Isolation
Each app runs in its own namespace (`argo-web` and `k8s-web`), allowing both to use the same internal port (5000) without conflicts.

### ArgoCD App-of-Apps Pattern
The `app-of-apps.yaml` monitors the `apps/` directory and deploys all Application manifests found there. This enables managing multiple applications from a single root application.

### Build Process
1. Run PowerShell script: `.\tools\build-argo-web.ps1` or `.\tools\build-k8s-web.ps1`
2. Scripts configure Docker CLI to use minikube's Docker daemon
3. Images are built directly into minikube's registry

### Deployment Workflow
1. Make code changes
2. Commit and push to GitHub main branch
3. Rebuild Docker images locally using build scripts
4. ArgoCD automatically syncs from GitHub repository
5. Restart deployments if needed: `kubectl rollout restart deployment <name> -n <namespace>`

## Important Notes
- ArgoCD reads from GitHub repository, not local files - always commit/push changes
- Image tags are versioned (v1.0) not `:latest`
- All Kubernetes manifests include explicit namespace declarations
- WORKDIR in Dockerfiles: `/app/src/argo-web` and `/app/src/k8s-web`
- Python import path in wsgi.py: `from app.main import app`

## Access Points
- argo-web: `http://$(minikube ip):30080`
- k8s-web: `http://$(minikube ip):30081`
- Or use: `minikube service <service-name> -n <namespace>`
```
