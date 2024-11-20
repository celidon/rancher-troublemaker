#!/bin/bash

MainDir=asdf
RANCHER_URL=$(grep url $MainDir/connection_info | cut -d'"' -f2)
RKC=$MainDir/tf/aws/kube_config_server.yaml

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if curl -o /dev/null -ILksf $RANCHER_URL; then
  echo -e "$GREEN[PASS]$NC Rancher URL is up and responding"
else
  echo -e "$RED[FAIL]$NC Rancher URL is not returning 200 OK"
  echo -e "$RED Remaining checks skipped $NC"
  exit 1
fi

helm --kubeconfig $RKC get values -n cattle-system rancher 2>/dev/null > values.yaml
CPU=$(grep cpu: values.yaml | cut -d: -f2 | tr -d " ")
MEM=$(grep memory: values.yaml | cut -d: -f2 | tr -d " ")

rm values.yaml

if [ $CPU != 1 ] || [ $MEM != "1G" ]; then
  echo -e "$RED[FAIL]$NC Resources not set correctly"
  echo -e "$RED Remaining checks skipped $NC"
  exit 1
else
  echo -e "$GREEN[PASS]$NC Resources set correctly"
fi

VER=$(helm get metadata rancher -n cattle-system 2>/dev/null | grep ^VERSION | cut -d" " -f2)

if [ $VER != "2.9.3" ]; then
  echo -e "$RED[FAIL]$NC Rancher version change"
  exit 1
else
  echo -e "$GREEN[PASS]$NC Rancher version set correctly"
fi
