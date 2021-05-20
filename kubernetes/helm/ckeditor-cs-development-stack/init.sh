#!/usr/bin/env bash
set -e

if [[ -z "$LICENSE_KEY" || -z "$DOCKER_TOKEN" ]]; then
  echo "Either LICENSE_KEY or DOCKER_TOKEN was not provided"
  exit 1
fi

# Install required tools
tools=( "minikube" "helm" )
for tool in "${tools[@]}"; do
  if ! command -v "$tool" &> /dev/null; then
      brew install "$tool"
  fi
done

# Provision minikube
if ! minikube status; then
    minikube start --cpus 4 --memory 4g
fi

# Enable addons
addons=( "ingress" "ingress-dns" "metrics-server" "dashboard" )

for addon in "${addons[@]}"; do
  if minikube addons list | grep -E "$addon.*enabled"; then 
    minikube addons enable "$addon"
  fi
done

# Create dns configuration for `ingress-dns` addon
sudo mkdir -p /etc/resolver
sudo bash -c "cat << EOF > /etc/resolver/minikube-test
domain test
nameserver $(minikube ip)
search_order 1
timeout 5
EOF"

# Create imagePullSecret for CKEditor container registry
if ! kubectl get secret docker-cke-cs-com; then
  kubectl create secret docker-registry docker-cke-cs-com \
      --docker-username "cs" \
      --docker-server "https://docker.cke-cs.com" \
      --docker-password="$DOCKER_TOKEN"
fi

# Add bitnami repository to helm
if ! helm repo list | grep bitnami; then
  helm repo add bitnami https://charts.bitnami.com/bitnami
fi

# Install helm chart in minikube cluster
helm repo update
helm dependency update
helm upgrade ckeditor-cs . \
  --install \
  --set server.secret.data.LICENSE_KEY="$LICENSE_KEY" \
  --wait \
  --timeout=5m

# Wait until 
