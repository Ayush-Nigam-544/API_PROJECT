#!/bin/bash
# ArgoCD Installation Script using Helm (Bash)
# This script installs ArgoCD using the official Helm chart with our custom values

set -e

# Default values
NAMESPACE="argocd"
VALUES_FILE="argocd-values.yaml"
UNINSTALL=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions for colored output
write_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

write_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

write_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

write_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --values-file)
            VALUES_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--uninstall] [--namespace NAMESPACE] [--values-file VALUES_FILE]"
            echo "  --uninstall      Uninstall ArgoCD"
            echo "  --namespace      Kubernetes namespace (default: argocd)"
            echo "  --values-file    Helm values file (default: argocd-values.yaml)"
            exit 0
            ;;
        *)
            write_error "Unknown option $1"
            exit 1
            ;;
    esac
done

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    write_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    write_error "helm is not installed or not in PATH"
    exit 1
fi

# Check if the dependent_services node exists and is ready
write_status "Checking cluster nodes..."
if ! kubectl get nodes -l type=dependent_services --no-headers &> /dev/null; then
    write_warning "No nodes found with label 'type=dependent_services'"
    write_status "Available nodes:"
    kubectl get nodes --show-labels
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        write_status "Installation cancelled"
        exit 0
    fi
else
    NODE_NAME=$(kubectl get nodes -l type=dependent_services --no-headers | awk '{print $1}')
    write_success "Found dependent_services node: $NODE_NAME"
fi

if [[ "$UNINSTALL" == true ]]; then
    write_status "Uninstalling ArgoCD..."
    helm uninstall argocd -n "$NAMESPACE" || true
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    write_success "ArgoCD uninstalled successfully! 🗑️"
    exit 0
fi

write_status "🚀 Installing ArgoCD with GitOps configuration..."

# Create namespace
write_status "Creating $NAMESPACE namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Add ArgoCD Helm repository
write_status "Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD with custom values
write_status "Installing ArgoCD with custom configuration..."
write_status "This may take several minutes - please wait..."

if ! helm upgrade --install argocd argo/argo-cd \
    --namespace "$NAMESPACE" \
    --values "$VALUES_FILE" \
    --timeout 15m \
    --wait; then
    write_error "Helm installation failed!"
    exit 1
fi

# Wait for ArgoCD server to be ready
write_status "Waiting for ArgoCD server to be ready..."
retry_count=0
max_retries=30
while [[ $retry_count -lt $max_retries ]]; do
    if kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=argocd-server --no-headers | grep -q "Running"; then
        write_success "ArgoCD server is ready!"
        break
    fi
    sleep 10
    ((retry_count++))
    write_status "Waiting for ArgoCD server... ($retry_count/$max_retries)"
done

if [[ $retry_count -eq $max_retries ]]; then
    write_warning "ArgoCD server may not be fully ready yet. Check pods manually."
fi

# Get the initial admin password
write_status "Retrieving ArgoCD admin password..."
sleep 5  # Give a moment for secret to be created
if ADMIN_PASSWORD_B64=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null); then
    ADMIN_PASSWORD=$(echo "$ADMIN_PASSWORD_B64" | base64 -d)
else
    ADMIN_PASSWORD="Password secret not found - check manually"
fi

# Get node IP for access
if NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null); then
    if [[ -z "$NODE_IP" ]]; then
        NODE_IP="localhost"
    fi
else
    NODE_IP="localhost"
fi

write_success "ArgoCD installation completed successfully! 🎉"
echo ""
echo -e "${BLUE}📋 Access Information:${NC}"
echo "   URL: http://${NODE_IP}:30080"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "   1. Access ArgoCD UI at the URL above"
echo "   2. Change the default admin password"
echo "   3. Deploy ArgoCD applications:"
echo "      kubectl apply -f applications/"
echo "   4. Configure repository connections if needed"
echo ""
echo -e "${BLUE}💡 Useful Commands:${NC}"
echo "   # Get admin password again:"
echo "   kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
echo ""
echo "   # Forward port for local access:"
echo "   kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443"
echo ""
echo "   # Check ArgoCD pods:"
echo "   kubectl get pods -n $NAMESPACE"
echo ""
echo "   # Uninstall ArgoCD:"
echo "   $0 --uninstall"
