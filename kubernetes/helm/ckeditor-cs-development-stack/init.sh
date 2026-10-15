#!/usr/bin/env bash
set -e

if [[ -z "$LICENSE_KEY" || -z "$DOCKER_TOKEN" ]]; then
  echo "Either LICENSE_KEY or DOCKER_TOKEN was not provided"
  exit 1
fi

# Authenticate user as sudoer at the start of the script
sudo echo ''

# Install required tools
tools=("minikube" "helm")
for tool in "${tools[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    brew install "$tool"
  fi
done

# Provision minikube
if ! minikube status; then
  minikube start --cpus 4 --memory 4g
fi

# Enable addons
addons=("ingress" "ingress-dns" "metrics-server" "dashboard")

for addon in "${addons[@]}"; do
  if minikube addons list | grep -E "$addon.*disabled"; then
    minikube addons enable "$addon"
  fi
done

# The ingress addon returns before its admission webhook accepts connections.
echo "Waiting for the ingress-nginx controller..."
for _ in {1..60}; do
  controller="$(kubectl get pod --namespace ingress-nginx \
    --selector app.kubernetes.io/component=controller \
    --output name 2>/dev/null)"
  if [[ -n "$controller" ]]; then
    break
  fi
  sleep 2
done

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector app.kubernetes.io/component=controller \
  --timeout=180s

# Create dns configuration for `ingress-dns` addon
sudo mkdir -p /etc/resolver
sudo bash -c "cat << EOF > /etc/resolver/minikube-test
domain test
nameserver $(minikube ip)
search_order 1
timeout 5
EOF"

# Create imagePullSecret for CKEditor container registry
if ! kubectl get secret docker-cke-cs-com &>/dev/null; then
  kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "cs" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="$DOCKER_TOKEN"
fi

# Install helm chart in minikube cluster
helm dependency update
echo "Running deployment of ckeditor-cs stack, this may take a while..."
helm upgrade ckeditor-cs . \
  --install \
  --set ckeditor-cs.server.secret.data.LICENSE_KEY="$LICENSE_KEY" \
  --wait \
  --timeout=10m
