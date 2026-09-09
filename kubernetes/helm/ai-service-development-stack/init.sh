#!/usr/bin/env bash
set -e

if [[ -z "$LICENSE_KEY" || -z "$DOCKER_TOKEN" || -z "$PROVIDERS" ]]; then
  echo "LICENSE_KEY, DOCKER_TOKEN and PROVIDERS all need to be provided"
  echo "Example:"
  echo "  LICENSE_KEY=xxx DOCKER_TOKEN=xxx \\"
  echo "    PROVIDERS='{\"openai\":{\"type\":\"openai\",\"apiKeys\":[\"xxx\"]}}' ./init.sh"
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
    --docker-username "ai-service" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="$DOCKER_TOKEN"
fi

# `PROVIDERS` is a stringified JSON object, so it is passed through a values
# file instead of `--set` to avoid escaping its commas and quotes.
# `dev.values.yaml` is git-ignored.
cat << EOF > dev.values.yaml
ai-service:
  secret:
    data:
      LICENSE_KEY: '$LICENSE_KEY'
      PROVIDERS: '$PROVIDERS'
EOF

# Install helm chart in minikube cluster
helm repo update
helm dependency update
helm upgrade ai-service . \
  --install \
  --values dev.values.yaml \
  --wait \
  --timeout=10m
