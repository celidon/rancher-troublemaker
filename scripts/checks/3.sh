#!/bin/bash

MainDir=asdf
IP=$(grep workload_node_ip $MainDir/connection_info | cut -d'"' -f2)
SSH="ssh ec2-user@$IP -i $MainDir/id_rsa -o StrictHostKeyChecking=no -C sudo"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ $( $SSH echo $(( $(stat -f / --printf="%a * 100 / %b") )) ) -gt 15 ]; then
  echo -e "$GREEN [PASS]$NC Disk usage is under Disk Pressure High Threshold"
else
  echo -e "$RED [FAIL]$NC Disk usage still too high"
  echo -e "$RED Remaining check skipped $NC"
  exit 1
fi

if $SSH stat /tmp/test &>/dev/null; then
  echo -e "$RED [FAIL]$NC Problem file still present"
  exit 1
else
  echo -e "$GREEN [PASS]$NC Large file removed"
fi
