# Minikube Deployment Guide

This document explains how to build and deploy the argo-web application to minikube using ArgoCD or kubectl.

## Overview

The deployment process consists of two main phases:

1. **Build Phase**: Build the Docker image inside minikube's Docker environment
2. **Deploy Phase**: Deploy the application to Kubernetes using kubectl or ArgoCD

## Architecture

```text
┌─────────────────┐
│ Your Computer   │
│  (Docker CLI)   │
└────────┬────────┘
         │
         │ minikube docker-env
         │ (points Docker CLI to minikube)
         │
         ▼
┌─────────────────────────────┐
│ Minikube VM                 │
│                             │
│  ┌──────────────────────┐   │
│  │ Docker Daemon        │   │
│  │                      │   │
│  │  argoweb:v1.0│   │
│  └──────────────────────┘   │
│           │                 │
│           │ imagePullPolicy: Never
│           │                 │
│  ┌────────▼─────────────┐   │
│  │ Kubernetes           │   │
│  │                      │   │
│  │  Pod: argo-web│   │
│  │  Service (NodePort)  │   │
│  └──────────────────────┘   │
│                             │
└─────────────────────────────┘
         │
         │ Port 30080
         ▼
    Your Browser
```

## How It Works

### Image Storage

Unlike Docker Desktop or container registries, minikube has its **own isolated Docker daemon**. When you build an image for minikube, it's stored inside the minikube VM, not in Docker Desktop.

**Key Point**: The Docker image is **built inside minikube**, not pulled from a registry.

### Build Process

The `build-argo-web.ps1` script automates the following steps:

1. **Check Prerequisites**: Verifies minikube is installed and running
2. **Configure Docker CLI**: Runs `minikube docker-env | Invoke-Expression` to point your local Docker CLI to minikube's Docker daemon
3. **Build Image**: Executes `docker build -t argoweb:v1.0 -f src/argo-web/Dockerfile .`
4. **Verify**: Confirms the image exists in minikube's registry

After this script completes, the image `argoweb:v1.0` exists in minikube but **nothing is running yet**.

### Deployment Configuration

#### deployment.yaml
```yaml
image: argoweb:v1.0
imagePullPolicy: Never  # Don't pull from registry, use local image only
```

The `imagePullPolicy: Never` tells Kubernetes: "This image is already in the local Docker daemon, don't try to pull it from a registry."

#### service.yaml
```yaml
type: NodePort        # Exposes the service outside minikube
port: 80              # External port
targetPort: 5000      # Container port (matches gunicorn config)
nodePort: 30080       # Fixed port on minikube node
```

### Deployment Process

**Option 1: Direct Deployment with kubectl**
```powershell
kubectl apply -f argo/deployment.yaml
kubectl apply -f argo/service.yaml
```

This creates:
- A Deployment with 1 replica running the argo-web container
- A NodePort Service exposing the app on port 30080

**Option 2: GitOps Deployment with ArgoCD**
```powershell
kubectl apply -f application.yaml
```

This creates an ArgoCD Application that:
- Monitors the `dev` branch of the GitHub repository
- Automatically syncs the manifests from the `argo/` folder
- Deploys to the `argo-web` namespace
- Auto-heals and prunes resources

## Complete Workflow

### Step-by-Step Process

```powershell
# 1. Start minikube (if not running)
minikube start

# 2. Build the Docker image inside minikube
.\tools\build-argo-web.ps1

# 3a. Deploy directly with kubectl
kubectl apply -f argo/deployment.yaml
kubectl apply -f argo/service.yaml

# OR

# 3b. Deploy via ArgoCD (requires ArgoCD installed)
kubectl apply -f application.yaml

# 4. Check deployment status
kubectl get pods -n argo-web
kubectl get svc -n argo-web

# 5. Access the application
minikube service argo-web-service -n argo-web
```

### What Happens at Each Step

1. **minikube start**: Starts the minikube VM with Kubernetes cluster
2. **build-argo-web.ps1**: Creates the Docker image inside minikube's Docker environment
3. **kubectl apply**: Creates Kubernetes resources (Deployment, Service) that reference the local image
4. **Kubernetes pulls image**: Uses the image from minikube's local Docker daemon (not a registry)
5. **Pod starts**: Container runs with gunicorn on port 5000
6. **Service routes traffic**: NodePort service exposes port 5000 as port 80 externally

## Image Storage Options

### Option 1: Local (Current Setup)
- **Image**: `argoweb:v1.0`
- **Policy**: `imagePullPolicy: Never`
- **Storage**: Minikube's internal Docker daemon
- **Use Case**: Local development, no internet required

### Option 2: GitHub Container Registry
- **Image**: `ghcr.io/RobDaPraia/argo-web:v1.0`
- **Policy**: `imagePullPolicy: Always`
- **Storage**: GitHub Container Registry
- **Use Case**: Sharing images, team collaboration

### Option 3: Azure Container Registry
- **Image**: `yourregistry.azurecr.io/argo-web:v1.0`
- **Policy**: `imagePullPolicy: Always`
- **Storage**: Azure Container Registry
- **Use Case**: Production deployments, enterprise

## Networking

### Port Mapping

```text
Browser Request → Minikube IP:30080 → Service:80 → Pod:5000 → Gunicorn
```

- **Port 80**: Service external port (what kubectl sees)
- **Port 5000**: Container port (gunicorn listens here, set by PORT env var)
- **Port 30080**: NodePort (how you access from outside minikube)

### Access Methods

```powershell
# Method 1: Automatic browser opening
minikube service argo-web-service -n argo-web

# Method 2: Get URL manually
minikube service argo-web-service -n argo-web --url
# Then open the URL in your browser

# Method 3: Direct IP access (if you know minikube IP)
minikube ip
# Then browse to http://<minikube-ip>:30080
```

## Troubleshooting

### Image Not Found Error
```
Error: ErrImagePull
```
**Cause**: The image doesn't exist in minikube's Docker daemon

**Solution**: Run the build script again
```powershell
.\tools\build-argo-web.ps1
```

### Pod Not Starting
```powershell
# Check pod status
kubectl get pods -n argo-web

# View pod logs
kubectl logs <pod-name> -n argo-web

# Describe pod for events
kubectl describe pod <pod-name> -n argo-web
```

### Service Not Accessible
```powershell
# Verify service exists
kubectl get svc -n argo-web

# Check endpoints
kubectl get endpoints -n argo-web

# Test service from inside cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- http://argo-web-service.argo-web.svc.cluster.local
```

### Rebuild and Redeploy
```powershell
# Delete existing deployment
kubectl delete -f argo/deployment.yaml

# Rebuild image
.\tools\build-argo-web.ps1

# Redeploy
kubectl apply -f argo/deployment.yaml
```

## ArgoCD Specific

### ArgoCD Application Configuration

The `application.yaml` file configures ArgoCD to:
- Monitor the `main` branch
- Pull manifests from the `argo/` folder
- Deploy to the `argo-web` namespace
- Auto-sync on changes
- Self-heal on drift
- Prune deleted resources

### Initial ArgoCD Setup

```powershell
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy the application
kubectl apply -f application.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Viewing Application Status

```powershell
# Via ArgoCD CLI
argocd app get hello-world-application

# Via kubectl
kubectl get application hello-world-application -n argocd

# Via ArgoCD UI
# Browse to https://localhost:8080
# Login as 'admin' with the password from above
```

## References

- [Minikube Docker Daemon](https://minikube.sigs.k8s.io/docs/handbook/pushing/#1-pushing-directly-to-the-in-cluster-docker-daemon-docker-env)
- [Kubernetes ImagePullPolicy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

