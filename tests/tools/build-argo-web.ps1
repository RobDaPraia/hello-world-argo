#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build Docker image for minikube deployment
.DESCRIPTION
    This script builds the hello-world-argo Docker image in minikube's Docker environment
    so it can be used by Kubernetes deployments without pulling from a registry.
.EXAMPLE
    .\tools\build-argo-web.ps1
#>

# Stop on errors
$ErrorActionPreference = "Stop"

Write-Host "🚀 Building Docker image for minikube..." -ForegroundColor Cyan
Write-Host ""

# Check if minikube is installed
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command minikube -ErrorAction SilentlyContinue)) {
    Write-Host "❌ ERROR: minikube is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Install from: https://minikube.sigs.k8s.io/docs/start/" -ForegroundColor Red
    exit 1
}

# Check if minikube is running
Write-Host "🔍 Checking minikube status..." -ForegroundColor Yellow
$minikubeStatus = minikube status --format='{{.Host}}' 2>&1
if ($minikubeStatus -ne "Running") {
    Write-Host "❌ ERROR: minikube is not running" -ForegroundColor Red
    Write-Host "   Start minikube with: minikube start" -ForegroundColor Red
    exit 1
}
Write-Host "✅ minikube is running" -ForegroundColor Green
Write-Host ""

# Configure Docker CLI to use minikube's Docker daemon
Write-Host "🔧 Configuring Docker CLI to use minikube..." -ForegroundColor Yellow
try {
    # Get the docker-env output and execute it
    & minikube docker-env | Invoke-Expression
    Write-Host "✅ Docker CLI configured for minikube" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Failed to configure Docker environment" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

# Build the Docker image
Write-Host "🏗️  Building Docker image..." -ForegroundColor Yellow
Write-Host "   Image: argoweb:v1.0" -ForegroundColor Gray
Write-Host "   Dockerfile: src/argo-web/Dockerfile" -ForegroundColor Gray
Write-Host ""

try {
    docker build -t argoweb:v1.0 -f src/argo-web/Dockerfile .
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: Docker build failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Docker image built successfully!" -ForegroundColor Green
Write-Host ""

# Verify the image exists
Write-Host "🔍 Verifying image in minikube..." -ForegroundColor Yellow
$imageCheck = docker images argoweb:v1.0 --format "{{.Repository}}:{{.Tag}}" 2>&1
if ($imageCheck -match "argoweb:v1.0") {
    Write-Host "✅ Image found: $imageCheck" -ForegroundColor Green
} else {
    Write-Host "⚠️  WARNING: Could not verify image" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✨ Success! Next steps:" -ForegroundColor Green
Write-Host ""
Write-Host "1. Apply the Kubernetes manifests:" -ForegroundColor White
Write-Host "   kubectl apply -f argo/deployment.yaml" -ForegroundColor Gray
Write-Host "   kubectl apply -f argo/service.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Check deployment status:" -ForegroundColor White
Write-Host "   kubectl get pods -n hello-world-argo" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Access the application:" -ForegroundColor White
Write-Host "   minikube service hello-world-argo-service -n hello-world-argo" -ForegroundColor Gray
Write-Host ""
Write-Host "OR deploy via ArgoCD:" -ForegroundColor White
Write-Host "   kubectl apply -f application.yaml" -ForegroundColor Gray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
