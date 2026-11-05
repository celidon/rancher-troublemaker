#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
MainDir=asdf
WKC=$MainDir/tf/aws/kube_config_workload.yaml

IP=$(grep workload_node_ip connection_info | cut -d'"' -f2)
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "app.$IP.nip.io")

if kubectl rollout status deployment --timeout=1s --kubeconfig $WKC &> /dev/null; then
  echo -e "$GREEN [PASS]$NC Deployment is running"
else
  echo -e "$RED [FAIL]$NC Deployment is$RED NOT$NC running"
  echo -e "$RED Remaining checks skipped $NC"
  exit 1
fi
if [ $STATUS_CODE -eq 200 ]; then
  echo -e "$GREEN [PASS]$NC Website is responding"
else
  echo -e "$RED [FAIL]$NC Website is$RED NOT$NC responding"
  echo -e "$RED Remaining check skipped $NC"
  exit 1
fi

if curl -sLk app.$IP.nip.io | grep Congrats > /dev/null; then
  echo -e "$GREEN [PASS]$NC Website data is correct"
else
  echo -e "$RED [FAIL]$NC Website data$RED NOT$NC correct"
  exit 1
fi

