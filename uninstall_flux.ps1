# Uninstall Flux from Kubernetes Cluster
# This script removes Flux and cleans up the cluster

param(
    [Parameter(Mandatory=$false)]
    [string]$RepositoryPath = "workshop-flux-bootstrap"
)

Write-Host "Uninstalling Flux from Kubernetes Cluster..." -ForegroundColor Green

# Check if kubectl is available
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "kubectl is available: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: kubectl is not available or not in PATH" -ForegroundColor Red
    Write-Host "Please install kubectl first" -ForegroundColor Yellow
    exit 1
}

# Remove finalizers from CRDs
Write-Host "Removing finalizers from Flux CRDs..." -ForegroundColor Yellow

try {
    # Remove finalizers from gitrepositories CRD
    Write-Host "Removing finalizers from gitrepositories.source.toolkit.fluxcd.io..." -ForegroundColor Yellow
    kubectl patch crd gitrepositories.source.toolkit.fluxcd.io -p '{"metadata":{"finalizers":[]}}' --type=merge
    
    # Remove finalizers from kustomizations CRD
    Write-Host "Removing finalizers from kustomizations.kustomize.toolkit.fluxcd.io..." -ForegroundColor Yellow
    kubectl patch crd kustomizations.kustomize.toolkit.fluxcd.io -p '{"metadata":{"finalizers":[]}}' --type=merge
    
    Write-Host "Finalizers removed successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to remove finalizers: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "You may need to manually edit the CRDs" -ForegroundColor Yellow
}

# Delete Flux resources from bootstrap repository
if (Test-Path $RepositoryPath) {
    Write-Host "Deleting Flux resources from bootstrap repository..." -ForegroundColor Yellow
    
    $installDir = "$RepositoryPath\install"
    
    if (Test-Path "$installDir\gotk-kustomization.yaml") {
        Write-Host "Deleting gotk-kustomization.yaml..." -ForegroundColor Yellow
        kubectl delete -f "$installDir\gotk-kustomization.yaml" --ignore-not-found
    }
    
    if (Test-Path "$installDir\gotk-repository.yaml") {
        Write-Host "Deleting gotk-repository.yaml..." -ForegroundColor Yellow
        kubectl delete -f "$installDir\gotk-repository.yaml" --ignore-not-found
    }
    
    if (Test-Path "$installDir\gotk-components.yaml") {
        Write-Host "Deleting gotk-components.yaml..." -ForegroundColor Yellow
        kubectl delete -f "$installDir\gotk-components.yaml" --ignore-not-found
    }
    
    Write-Host "Bootstrap resources deleted successfully" -ForegroundColor Green
}

# Delete Flux system namespace and all resources
Write-Host "Deleting Flux system namespace..." -ForegroundColor Yellow
try {
    kubectl delete namespace flux-system --ignore-not-found
    Write-Host "Flux system namespace deleted successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to delete flux-system namespace: $($_.Exception.Message)" -ForegroundColor Red
}

# Delete Flux CRDs
Write-Host "Deleting Flux CRDs..." -ForegroundColor Yellow
try {
    kubectl get crd | Select-String "flux" | ForEach-Object {
        $crdName = ($_ -split '\s+')[0]
        Write-Host "Deleting CRD: $crdName" -ForegroundColor Yellow
        kubectl delete crd $crdName --ignore-not-found
    }
    Write-Host "Flux CRDs deleted successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to delete Flux CRDs: $($_.Exception.Message)" -ForegroundColor Red
}

# Clean up deployed applications
Write-Host "Cleaning up deployed applications..." -ForegroundColor Yellow
try {
    # Delete sample app if it exists
    kubectl delete deployment sample-app -n default --ignore-not-found
    kubectl delete service sample-app-service -n default --ignore-not-found
    
    Write-Host "Deployed applications cleaned up successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to clean up applications: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nFlux uninstallation complete!" -ForegroundColor Green
Write-Host "Note: You may need to manually clean up any remaining resources" -ForegroundColor Yellow
Write-Host "Check for remaining resources: kubectl get all --all-namespaces | Select-String 'flux'" -ForegroundColor Cyan 