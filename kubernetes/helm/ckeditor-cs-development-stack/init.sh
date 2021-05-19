#!/usr/bin/env bash
set -e

# Provision minikube
if [[ -z "$(which minikube)" ]]; then
    brew install minikube 
fi

if minikube status | grep -qE 'not found|host: Stopped'; then
    minikube start --cpus 4 --memory 4g
fi

# Enable addons
addons=( "ingress" "ingress-dns" "metrics-server" "dashboard" )

for addon in "${addons[@]}"; do
  minikube addons enable "$addon"
done

# Create dns configuration for `ingress-dns` addon
sudo bash -c "cat << EOF > /etc/resolver/minikube-test
domain test
nameserver $(minikube ip)
search_order 1
timeout 5
EOF"
