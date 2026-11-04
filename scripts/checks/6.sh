#!/bin/bash

MainDir=asdf
RKC=$MainDir/tf/aws/kube_config_server.yaml
IP=$(grep workload_node_ip $MainDir/connection_info | cut -d'"' -f2)
SSH="ssh ec2-user@$IP -i $MainDir/id_rsa -o StrictHostKeyChecking=no -C sudo"
RANCHER_URL=$(grep url $MainDir/connection_info | cut -d'"' -f2 | cut -d/ -f3)
CA_CHECKSUM=

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if kubectl --kubeconfig $RKC get secrets -n cattle-system tls-ca -oyaml | grep cacerts.pem &>/dev/null; then
  echo -e "$GREEN[PASS]$NC tls-ca secret fixed"
else
  echo -e "$RED[FAIL]$NC Rancher still crash looping"
  echo -e "$RED Remaining checks skipped $NC"
  exit 1
fi

if [ $(echo | openssl s_client -showcerts -servername $RANCHER_URL -connect $RANCHER_URL:443 2>/dev/null | openssl x509 -inform pem -noout -text | grep DNS | cut -d: -f2) == $RANCHER_URL ] && [ "$(echo | openssl s_client -showcerts -servername $RANCHER_URL -connect $RANCHER_URL:443 2>/dev/null | openssl x509 -inform pem -noout -text | grep Issuer: | cut -d: -f2)" == " C=US, ST=SUSE, L=Rancher, O=Rancher TroubleMaker, OU=Problems, CN=TroubleMaker CA Root" ]; then
  echo -e "$GREEN[PASS]$NC Correct TLS Certificate in place and used"
else
  echo -e "$RED[FAIL]$NC Incorrect TLS Certificate in use"
  echo -e "$RED Remaining checks skipped $NC"
  exit 1
fi

if [ "$(curl -k -s -fL $RANCHER_URL/v3/settings/cacerts | tr , "\n" | grep value | cut -d'"' -f4 | sed 's/\\n/\n/g' | sha256sum | cut -d" " -f1)" == "$CA_CHECKSUM" ]; then
  echo -e "$GREEN[PASS]$NC Correct CA certificate in place"
else
  echo -e "$RED[FAIL]$NC Incorrect CA at $RANCHER_URL/v3/settings/cacerts"
  echo -e "$RED Remaining check skipped $NC"
  exit 1
fi

if [ "$($SSH /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get deploy -n cattle-system cattle-cluster-agent -o yaml | grep -A1 CHECKSUM | grep "value: " | cut -d: -f2)" == " $CA_CHECKSUM" ]; then
  echo -e "$GREEN[PASS]$NC Correct CA_CHECKSUM configured for cattle-cluster-agent"
else
  echo -e "$RED[FAIL]$NC Incorrect CA_CHECKSUM configured for cattle-cluster-agent "
  exit 1
fi
