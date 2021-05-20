#!/usr/bin/env bash

base64Decode='base64 -D'

if [[ "$OSTYPE" == "darwin*" ]]; then
    base64Decode='base64 -d'
fi

if ! command -v jq &> /dev/null; then
    if [[ "$OSTYPE" == "darwin*" ]]; then
        brew install jq
    else
        echo "Error: \"jq\" commandline tool is required"
        exit 1
    fi
fi

kubectl run ckeditor-cs-tests -i --rm \
    --image docker.cke-cs.com/cs-tests:"$(kubectl get deployments.apps ckeditor-cs-server -o json | jq -r '.spec.template.spec.containers[0].image' | sed 's/.*://')" \
    --env APPLICATION_ENDPOINT="$(kubectl get ingresses.networking.k8s.io ckeditor-cs-server -o json | jq -r '.spec.rules[0].host' | sed 's|^|http://|')" \
    --env ENVIRONMENTS_MANAGEMENT_SECRET_KEY="$(kubectl get secret ckeditor-cs-server -o json | jq -r '.data.ENVIRONMENTS_MANAGEMENT_SECRET_KEY' | $base64Decode)" \
    --overrides='{ "spec": { "imagePullSecrets": [{"name": "docker-cke-cs-com"}] } }' \
    --restart='Never'
