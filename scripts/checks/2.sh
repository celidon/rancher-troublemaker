#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
MainDir=asdf

SNAPSHOT=on-demand-ip-10-0-0-238-1732045346

IP=$(grep workload_node_ip connection_info | cut -d'"' -f2)
SSH="ssh ec2-user@$IP -i ./id_rsa -o StrictHostKeyChecking=no -C sudo"

if $SSH which rke2 &>/dev/null; then
  echo -e "$GREEN [PASS]$NC RKE2 is installed"
else
  echo -e "$RED [FAIL]$NC RKE2 is$RED NOT$NC installed"
  echo -e "$RED Remaining checks skipped $NC"
  exit 1
fi

if $SSH systemctl is-active --quiet rke2-server; then
  echo -e "$GREEN [PASS]$NC RKE2 is running"
else
  echo -e "$RED [FAIL]$NC RKE2 is$RED NOT$NC running"
  echo -e "$RED Remaining checks skipped $NC"
  exit 1
fi

if $SSH ls /var/lib/rancher/rke2/server/db/snapshots | grep $SNAPSHOT >/dev/null; then
  echo -e "$GREEN [PASS]$NC RKE2 Snapshot is present in /var/lib/rancher/rke2/server/db/snapshots"
else
  echo -e "$RED [FAIL]$NC RKE2 Snapshot is$RED MISSING$NC"
  echo -e "$RED Remaining check skipped $NC"
  exit 1
fi

if curl -sILk $IP:30081 > /dev/null; then
  echo -e "$GREEN [PASS]$NC App is running"
else
  echo -e "$RED [FAIL]$NC App is$RED NOT$NC running"
  exit 1
fi
