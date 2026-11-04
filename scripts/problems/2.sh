#!/bin/bash
#Can't login to Rancher

MainDir=asdf
RKC=$MainDir/tf/aws/kube_config_server.yaml

kubectl --kubeconfig $RKC exec -n cattle-system $(kubectl --kubeconfig $RKC -n cattle-system get pods -l app=rancher --no-headers | head -1 | awk '{ print $1 }') -it -- reset-password > /dev/null
PW=$(kubectl --kubeconfig $RKC get users -oyaml | grep -B10 "username: admin" | grep password | cut -d: -f2 | tr -d " ")
USER=$(kubectl --kubeconfig $RKC get users -oyaml | grep -B10 "username: admin" | grep " name:" | cut -d: -f2 | tr -d " ")
sed -i "s|PW=.*$|PW=$PW|" $MainDir/scripts/checks/1.sh
sed -i "s|USER=.*$|USER=$USER|" $MainDir/scripts/checks/1.sh

echo "Ooops! The Rancher login password has been lost. Please reset it"
