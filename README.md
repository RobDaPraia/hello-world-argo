# Hello World Argo

A demonstration project for learning ArgoCD and GitOps on Kubernetes using minikube. This repository contains two Flask web applications deployed using ArgoCD's App-of-Apps pattern.

## 📋 Overview

This project demonstrates:
- **GitOps deployment** with ArgoCD monitoring the GitHub repository
- **App-of-Apps pattern** for managing multiple applications
- **Local Kubernetes development** using minikube with local Docker images
- **Multi-application architecture** with two separate Flask web apps (argo-web and k8s-web)

**Applications:**
- `argo-web` - Flask application deployed to the `argo-web` namespace (NodePort 30080)
- `k8s-web` - Flask application deployed to the `k8s-web` namespace (NodePort 30081)

**Technology Stack:**
- Python 3.13 with Flask
- Docker for containerization
- Kubernetes (minikube) for orchestration
- ArgoCD for GitOps continuous delivery
- UV for Python dependency management

## 🏗️ Building for Minikube

To deploy this application to minikube, you need to build the Docker image inside minikube's Docker environment.

### 🚀 Using the Build Script (Recommended)

```powershell
# Start minikube (if not running)
minikube start

# Build the images in minikube
.\tools\build-argo-web.ps1
.\tools\build-k8s-web.ps1
```

The scripts will:
- Verify minikube is running
- Configure your Docker CLI to use minikube's Docker daemon
- Build the image `argoweb:v1.0` and `k8sweb:v1.0`
- Verify the image was created

### ⚙️ Manual Build (Alternative)

If you prefer to build manually:

```powershell
# Configure Docker to use minikube
minikube docker-env | Invoke-Expression

# Build the image
docker build -t argoweb:v1.0 -f src/argo-web/Dockerfile .
docker build -t k8sweb:v1.0 -f src/k8s-web/Dockerfile .

# Verify the image exists
docker images argoweb:v1.0
docker images k8sweb:v1.0
```

### 💡 Why Build in Minikube?

The Kubernetes deployment uses `imagePullPolicy: Never`, which means it expects the image to be available in minikube's local Docker registry, not pulled from a remote registry. This is perfect for local development as it:
- Speeds up deployment (no image push/pull)
- Works without internet connection
- Doesn't require container registry setup


### 🗑️ Removing Images from Minikube

To clean up old images from minikube's Docker registry:

```powershell
# Configure Docker to use minikube
minikube docker-env | Invoke-Expression

# List all images in minikube
docker images

# Remove specific image
docker rmi argoweb:v1.0
docker rmi k8sweb:v1.0

# Remove all unused images (cleanup)
docker image prune -a

# Remove specific image forcefully
docker rmi -f argoweb:v1.0
```

**Note**: After removing an image, you'll need to rebuild it before deploying the application again.

### 🚢 Deploying App-of-Apps

After building the images:

1. **Commit and push changes to GitHub** (ArgoCD reads from the GitHub repository):
   ```powershell
   git add -A
   git commit -m "Update application configuration"
   git push
   ```

2. **Deploy with ArgoCD** (recommended):
   ```powershell
   kubectl apply -f app-of-apps.yaml
   ```

3. **Access the applications**:
   ```powershell
   minikube service argo-web-service -n argo-web
   minikube service k8s-web-service -n k8s-web
   ```

For detailed deployment instructions, see [docs/argocd-installation.md](docs/argocd-installation.md) and [docs/minikube-deployment.md](docs/minikube-deployment.md).

## 🧹 Cleaning Up Argo CD Applications

```powershell
# Delete all applications (including app-of-apps and children)
kubectl delete applications --all -n argocd

# Clean up application namespace
kubectl delete namespace argo-web
```
