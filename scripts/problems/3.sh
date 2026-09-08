#!/bin/bash
#Disk pressure

MainDir=asdf
WKC=$MainDir/tf/aws/kube_config_workload.yaml
IP=$(grep workload_node_ip $MainDir/connection_info | cut -d'"' -f2)
SSH="ssh ec2-user@$IP -i $MainDir/id_rsa -o StrictHostKeyChecking=no -C sudo"

$SSH touch /tmp/test
$SSH 'cat > test.sh' <<< 'while true; do if [ $(df --output=pcent / | tail -1 | cut -d% -f1) -lt 95 ]; then if [ -f /tmp/test ]; then rm /tmp/test; fallocate -l $(( $( stat -f --printf="%a * %s" / ) / 100 * 95 )) /tmp/test; else exit; fi; sleep 10; fi; done'
$SSH bash test.sh &
$SSH mkdir .kube
$SSH cp /etc/rancher/rke2/rke2.yaml ./.kube/config
$SSH chown -R ec2-user. .kube
$SSH 'cat > .bashrc' <<< 'export PATH=$PATH:/var/lib/rancher/rke2/bin'

echo "Downstream cluster went offline. Please investigate why and bring it back online."

read -p "Would you like a hint? (y/n) " hint

if [ $hint == y ] || [ $hint == Y ]; then
    echo "You need to relieve the pressure"
fi
