# Accessing the Application

This guide explains how to access your argo-web application running in minikube.

## Understanding the Network Setup

When you run Kubernetes in minikube, it creates an isolated environment (VM or container) with its own network. Your application is running **inside minikube**, not directly on your Windows machine.

```
Your Windows Machine (localhost)
    │
    │ minikube is a separate VM
    ▼
┌─────────────────────────────┐
│ Minikube VM                 │
│ IP: 192.168.x.x (example)   │
│                             │
│  ┌──────────────────────┐   │
│  │ Kubernetes Cluster   │   │
│  │                      │   │
│  │  Service:            │   │
│  │  NodePort 30080      │   │
│  │                      │   │
│  │  Pod: argo-web    │   │
│  │  Port: 5000          │   │
│  └──────────────────────┘   │
└─────────────────────────────┘
```

**Important**: `http://localhost` will NOT work because the service is running inside minikube, not on your local machine.

## Recommended Method: minikube service Command

**This is the easiest and recommended way to access your application.**

Simply run:

```powershell
minikube service argo-web-service -n argo-web
```

This command will:
- Automatically determine the correct URL
- Open your default browser
- Navigate to your application

No need to remember IPs or ports!

## Alternative Access Methods

### Option 2: Get the URL Manually

If you prefer to manually open the URL:

```powershell
minikube service argo-web-service -n argo-web --url
```

This displays the URL (something like `http://192.168.49.2:30080`). Copy and paste it into your browser.

### Option 3: Port Forwarding to localhost (Not Recommended)

If you specifically need to use `http://localhost`, you can create a port forward:

```powershell
kubectl port-forward -n argo-web service/argo-web-service 8080:80
```

Then access via `http://localhost:8080`

**Drawbacks:**
- **Temporary**: Only works while the command is running
- Must keep the terminal window open
- Connection closes if you press Ctrl+C or close the terminal

### Option 4: Direct IP Access

Get minikube's IP address:

```powershell
minikube ip
```

Then access your application at: `http://<minikube-ip>:30080`

For example: `http://192.168.49.2:30080`

### Option 5: Custom Hostname (Advanced)

For a friendly hostname, add an entry to your hosts file:

1. Get minikube IP: `minikube ip` (e.g., `192.168.49.2`)
2. Open `C:\Windows\System32\drivers\etc\hosts` as Administrator
3. Add this line: `192.168.49.2 argo-web.local`
4. Save the file
5. Access via: `http://argo-web.local:30080`

**Note**: You'll need to update the IP if minikube restarts with a different IP.

## Port Mapping Explained

The service uses the following port configuration:

```
Browser Request → Minikube IP:30080 → Service:80 → Pod:5000 → Gunicorn
```

- **Port 80**: Service internal port (what kubectl sees)
- **Port 5000**: Container port (where gunicorn listens, set by PORT env var)
- **Port 30080**: NodePort (external access port)

## Troubleshooting

### Service not accessible

Check if the service exists:
```powershell
kubectl get svc -n argo-web
```

Check if pods are running:
```powershell
kubectl get pods -n argo-web
```

### Pod not ready

View pod logs:
```powershell
kubectl logs <pod-name> -n argo-web
```

Describe pod for events:
```powershell
kubectl describe pod <pod-name> -n argo-web
```

### Wrong URL from minikube service

If the URL doesn't work, verify minikube is running:
```powershell
minikube status
```

## Quick Reference

```powershell
# Access the application (RECOMMENDED)
minikube service argo-web-service -n argo-web

# Get the URL
minikube service argo-web-service -n argo-web --url

# Check service status
kubectl get svc -n argo-web

# Check pods
kubectl get pods -n argo-web

# View logs
kubectl logs -l app=argo-web -n argo-web
```

