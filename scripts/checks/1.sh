#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
MainDir=asdf

IP=$(grep workload_node_ip connection_info | cut -d'"' -f2)
if curl -sILk app.$IP.nip.io > /dev/null; then
  echo -e "$GREEN [PASS]$NC App is running"
else
  echo -e "$RED [FAIL]$NC App is$RED NOT$NC running"
  exit 1
fi

