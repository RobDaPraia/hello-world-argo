# ArgoCD Installation and Setup Guide

This guide explains how to install ArgoCD in minikube and deploy the argo-web application using GitOps.

## Prerequisites

- Minikube running: `minikube start`
- kubectl configured and working
- Git repository accessible (this repo on GitHub)

## Overview

ArgoCD is a declarative GitOps continuous delivery tool for Kubernetes. It monitors your Git repository and automatically syncs your Kubernetes manifests to the cluster.

```
GitHub Repository (main branch)
        │
        │ ArgoCD monitors
        ▼
┌─────────────────────────┐
│ ArgoCD Application      │
│ (application.yaml)      │
└────────┬────────────────┘
         │
         │ Syncs manifests from argo-templates/ folder
         ▼
┌─────────────────────────┐
│ Kubernetes Resources    │
│ - Deployment            │
│ - Service               │
└─────────────────────────┘
```

## Step 1: Install ArgoCD

### Create ArgoCD Namespace

```powershell
kubectl create namespace argocd
```

### Install ArgoCD

```powershell
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

This installs all ArgoCD components including:
- API Server
- Repository Server
- Application Controller
- Redis
- Dex (for SSO)

### Wait for ArgoCD to be Ready

```powershell
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

Or check manually:
```powershell
kubectl get pods -n argocd
```

All pods should be in `Running` state.

## Step 2: Access ArgoCD UI

ArgoCD provides a web UI for managing applications. You have several options to access it:

### Option 1: Port Forward (Recommended for Local Development)

```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then access the UI at: **https://localhost:8080**

**Note**: 
- Keep this terminal window open
- The connection is HTTPS with a self-signed certificate (your browser will warn you - it's safe to proceed)

### Option 2: Minikube Service (Alternative)

Change the service type to NodePort:

```powershell
kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"NodePort\"}}'
```

Then get the URL:

```powershell
minikube service argocd-server -n argocd --url
```

Access the URL shown (will be something like `http://192.168.49.2:xxxxx`)

## Step 3: Get ArgoCD Admin Password

The default username is: **admin**

Get the password:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

**Copy this password** - you'll need it to login.

### Login to ArgoCD UI

1. Open the ArgoCD UI (https://localhost:8080 or the minikube service URL)
2. Accept the self-signed certificate warning
3. Username: `admin`
4. Password: (the password from above)

## Step 4: Deploy the Application

Now that ArgoCD is installed, you can deploy your application. There are two approaches:

### Option A: Simple Application (Single App)

Use `application.yaml` to deploy a single application directly:

```powershell
kubectl apply -f application.yaml
```

This creates one ArgoCD Application that deploys from the `argo-templates/` folder.

### Option B: App-of-Apps Pattern (Recommended for Multiple Apps)

Use `app-of-apps.yaml` to deploy one or more applications:

```powershell
kubectl apply -f app-of-apps.yaml
```

This creates a parent application that manages child applications from the `apps/` folder. **This is the recommended approach as it scales better** - see the [App-of-Apps Pattern](#app-of-apps-pattern-advanced) section below for details.

### Verify Deployment

After applying either option, check the application status:

```powershell
kubectl get applications -n argocd
```

**Option A Output:**
```
NAME                      SYNC STATUS   HEALTH STATUS
hello-world-application   Synced        Healthy
```

**Option B Output:**
```
NAME               SYNC STATUS   HEALTH STATUS
app-of-apps        Synced        Healthy
argo-web   Synced        Healthy
```

With Option B, you'll see both the parent (`app-of-apps`) and child (`argo-web`) applications.

### What ArgoCD Does

The Application resource tells ArgoCD to:
- Monitor the `main` branch of `https://github.com/RobDaPraia/argo-web`
- Pull Kubernetes manifests from the `argo-templates/` folder
- Deploy to the `argo-web` namespace
- Automatically sync changes
- Self-heal if resources drift
- Prune deleted resources

### Verify Application Creation

```powershell
kubectl get application hello-world-application -n argocd
```

Expected output:
```
NAME                      SYNC STATUS   HEALTH STATUS
hello-world-application   Synced        Healthy
```

## Step 5: Monitor in ArgoCD UI

In the ArgoCD UI, you should see:

1. **Application Card**: `hello-world-application`
2. **Sync Status**: Should show "Synced" (green)
3. **Health Status**: Should show "Healthy" (green)

Click on the application to see:
- Visual representation of all resources (Deployment, Service, Pod)
- Real-time status updates
- Sync history
- Logs from pods

## Step 6: Access Your Application

Once ArgoCD has synced the application, access it using:

```powershell
minikube service argo-web-service -n argo-web
```

This opens your application in the browser.

See [accessing-the-application.md](accessing-the-application.md) for more details on accessing the application.

## Understanding the Application Configuration

The `application.yaml` file contains the following configuration:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hello-world-application
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/RobDaPraia/argo-web
    targetRevision: main      # Monitors main branch
    path: argo                # Looks for manifests in argo-templates/ folder
    
  destination:
    server: https://kubernetes.default.svc
    namespace: argo-web
    
  syncPolicy:
    syncOptions:
      - CreateNamespace=true  # Creates namespace if it doesn't exist
    automated:
      selfHeal: true          # Fixes drift automatically
      prune: true             # Removes deleted resources
```

### Key Configuration Options

- **targetRevision**: Which branch/tag to monitor (set to `main`)
- **path**: Folder containing Kubernetes manifests (`argo-templates/`)
- **namespace**: Target namespace for deployment (`argo-web`)
- **automated sync**: ArgoCD automatically applies changes from Git
- **selfHeal**: If someone manually changes resources, ArgoCD reverts them
- **prune**: If you delete a manifest from Git, ArgoCD deletes it from the cluster

## GitOps Workflow

Once ArgoCD is set up, your workflow becomes:

1. **Make changes** to manifests in the `argo-templates/` folder
2. **Commit and push** to the `main` branch on GitHub
3. **ArgoCD automatically detects** the changes (polls every 3 minutes by default)
4. **ArgoCD syncs** the changes to the cluster
5. **View status** in the ArgoCD UI

**No manual `kubectl apply` needed!**

## App-of-Apps Pattern (Advanced)

The App-of-Apps pattern allows you to manage multiple applications with a single root ArgoCD Application. This is useful when you have multiple microservices or environments. Each application appears as a separate card in the ArgoCD dashboard.

### How It Works

```
Root Application (app-of-apps)
    │
    ├── Application 1 (argo-web)
    ├── Application 2 (future-app-2)
    └── Application 3 (future-app-3)
```

Each child application is visible separately in the ArgoCD UI, making it easier to manage and monitor multiple services.

### Repository Structure

This repository uses the following structure for app-of-apps:

```
.
├── app-of-apps.yaml           # Root application (apply this)
├── apps/                      # ArgoCD Application manifests
│   └── argo-web.yaml  # Child application definition
└── argo-templates/                      # Kubernetes manifests
    ├── deployment.yaml        # Deployment resource
    └── service.yaml           # Service resource
```

**Key Points:**
- `apps/` folder contains **ArgoCD Application manifests** (child apps)
- `argo-templates/` folder contains **Kubernetes manifests** (deployment, service, etc.)
- Each child Application in `apps/` points to a folder with Kubernetes resources

### The Root Application (app-of-apps.yaml)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd              # Deploy child Applications to argocd namespace
  source:
    path: apps                     # Look for Application manifests in apps/
    repoURL: "https://github.com/RobDaPraia/argo-web"
    targetRevision: HEAD
  project: default
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true
```

### Child Application (apps/argo-web.yaml)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argo-web
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/RobDaPraia/argo-web
    targetRevision: main
    path: argo                      # Points to Kubernetes manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: argo-web     # Deploy K8s resources to this namespace
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      selfHeal: true
      prune: true
```

### Deploying with App-of-Apps

**Step 1:** Apply the root application:
```powershell
kubectl apply -f app-of-apps.yaml
```

**Step 2:** Wait a few seconds for sync:
```powershell
kubectl get applications -n argocd
```

Expected output:
```
NAME               SYNC STATUS   HEALTH STATUS
app-of-apps        Synced        Healthy
argo-web   Synced        Healthy
```

**Step 3:** View in ArgoCD UI

You'll see **both applications** as separate cards:
- **app-of-apps**: The parent application managing child apps
- **argo-web**: The actual application with your Deployment and Service

Click on `argo-web` to see the Kubernetes resources (Pod, Deployment, Service).

### Adding More Applications

To add another application:

1. **Create Kubernetes manifests** in a new folder (e.g., `argo-app2/`)
2. **Create Application manifest** in `apps/` folder (e.g., `apps/app2.yaml`)
3. **Commit and push** to GitHub
4. **ArgoCD automatically deploys** the new application

Example structure with multiple apps:
```
.
├── app-of-apps.yaml
├── apps/
│   ├── argo-web.yaml
│   ├── frontend-app.yaml
│   └── backend-app.yaml
├── argo-templates/                      # argo-web manifests
│   ├── deployment.yaml
│   └── service.yaml
├── argo-frontend/             # frontend-app manifests
│   ├── deployment.yaml
│   └── service.yaml
└── argo-backend/              # backend-app manifests
    ├── deployment.yaml
    └── service.yaml
```

### Important Notes

**Commit Changes to GitHub**: ArgoCD syncs from your GitHub repository, not local files. Always:
```powershell
git add -A
git commit -m "Your changes"
git push
```

**Both Applications Must Be in argocd Namespace**: ArgoCD only monitors Applications in the `argocd` namespace, even though the actual resources (Pods, Services) can deploy to any namespace.

**Namespace Configuration**:
- `app-of-apps` destination namespace: `argocd` (where child Applications are created)
- Child Application destination namespace: `argo-web` (where Kubernetes resources are created)

## Useful Commands

### View All Applications
```powershell
kubectl get applications -n argocd
```

### Get Application Details
```powershell
kubectl describe application hello-world-application -n argocd
```

### Manual Sync (if automated sync is disabled)
```powershell
kubectl patch application hello-world-application -n argocd --type merge -p '{\"operation\": {\"initiatedBy\": {\"username\": \"admin\"}, \"sync\": {\"revision\": \"main\"}}}'
```

Or use the ArgoCD UI "Sync" button.

### View ArgoCD Server Logs
```powershell
kubectl logs -n argocd deployment/argocd-server
```

### View Application Controller Logs
```powershell
kubectl logs -n argocd deployment/argocd-application-controller
```

### Restart ArgoCD (if needed)
```powershell
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-application-controller -n argocd
```

## Troubleshooting

### Application Shows "OutOfSync"

This means the Git repository differs from the cluster state.

**Solution**: Click "Sync" in the UI or wait for automated sync (if enabled).

### Application Shows "Unknown" Health Status

This typically means ArgoCD is still analyzing the resources.

**Solution**: Wait a few moments, or check the resource details.

### Cannot Connect to Repository

**Issue**: ArgoCD can't access the GitHub repository.

**Solution**: 
- Verify the repository URL in `application.yaml` is correct
- For private repos, add repository credentials in ArgoCD settings

### Pods Not Starting

**Issue**: Pods in `CrashLoopBackOff` or `ImagePullBackOff`.

**Solution**: 
- For `ImagePullBackOff`: Ensure the Docker image is built in minikube (run `.\tools\build-argo-web.ps1`)
- For `CrashLoopBackOff`: Check pod logs: `kubectl logs -n argo-web <pod-name>`

### ArgoCD UI Not Accessible

**Issue**: Port forward not working.

**Solution**:
- Ensure the port-forward command is still running
- Try a different port: `kubectl port-forward svc/argocd-server -n argocd 9090:443`
- Check ArgoCD server is running: `kubectl get pods -n argocd`

## Clean Up

### Delete the Application
```powershell
kubectl delete -f application.yaml
```

### Uninstall ArgoCD
```powershell
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

## Additional Resources

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://www.gitops.tech/)
- [App-of-Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)

## Next Steps

1. Explore the ArgoCD UI and familiarize yourself with the interface
2. Make a change to a manifest in the `argo-templates/` folder, commit, and watch ArgoCD sync it
3. Try rolling back a deployment using ArgoCD's history feature
4. Set up notifications for sync failures (webhook or Slack integration)
5. Explore multi-environment deployments (dev, staging, production)


