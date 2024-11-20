#!/bin/bash
#High Requests

MainDir=asdf
RKC=$MainDir/tf/aws/kube_config_server.yaml

helm --kubeconfig $RKC get values -n cattle-system rancher 2>/dev/null > values.yaml
cat >> values.yaml << EOF
resources:
  requests:
    cpu: 11111
    memory: 11111G
EOF

helm repo add rancher-prime https://charts.rancher.com/server-charts/prime &>/dev/null
helm repo update &>/dev/null
helm --kubeconfig $RKC upgrade rancher rancher-prime/rancher -n cattle-system -f values.yaml --version 2.9.3 &>/dev/null

kubectl --kubeconfig $RKC patch -n cattle-system deployments.apps rancher --type=json -p='[{"op": "replace", "path": "/spec/strategy/type", "value":"Recreate"}, {"op": "remove", "path": "/spec/strategy/rollingUpdate"}]' &>/dev/null

rm values.yaml

echo "Rancher isn't running. Please get it back online"

read -p "Would you like a hint? (y/n) " hint

if [ $hint == y ] || [ $hint == Y ]; then
    echo "I think I messed up editing my Helm values. I was trying to add resource requests of 1 CPU and 1G Memory."
fi
