#!/bin/bash

MainDir=asdf
RKC=$MainDir/tf/aws/kube_config_server.yaml
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PW=$2a$10$MRg6dbZUzgh.C9o2Xd29BuIZOO/vmBuNW/aQ/K7APwwNG6lAZ2Ts6
USER=user-qc89w

PWcurrent=$(kubectl --kubeconfig $RKC get users -oyaml | grep -B10 "username: admin" | grep password | cut -d: -f2 | tr -d " ")
USERcurrent=$(kubectl --kubeconfig $RKC get users -oyaml | grep -B10 "username: admin" | grep " name:" | cut -d: -f2 | tr -d " ")

if [ $PWcurrent != $PW ]; then
  echo -e "$GREEN [PASS]$NC Password changed"
else
  echo -e "$RED [FAIL]$NC Password not changed"
  echo -e "$RED Remaining check skipped $NC"
  exit 1
fi

if [ $USERcurrent == $USER ]; then
  echo -e "$GREEN [PASS]$NC Same user in use"
else
  echo -e "$RED [FAIL]$NC User changed"
  echo -e "$RED [WARN]$NC You might experience issues when you try to destroy the lab"
  exit 1
fi

