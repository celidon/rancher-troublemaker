#!/bin/bash
#Disk pressure

MainDir=asdf
WKC=$MainDir/tf/aws/kube_config_workload.yaml
IP=$(grep workload_node_ip $MainDir/connection_info | cut -d'"' -f2)
SSH="ssh ec2-user@$IP -i $MainDir/id_rsa -o StrictHostKeyChecking=no -C sudo"

$SSH touch /tmp/test
$SSH 'cat > test.sh' <<< 'while true; do if [ -f /tmp/test ]; then rm /tmp/test; fallocate -l $(( $( stat -f --printf="%a * %s" / ) / 100 * 98 )) /tmp/test; else exit; fi; sleep 10; done'
$SSH bash test.sh &

echo "Downstream cluster went offline. Please investigate why and bring it back online."

read -p "Would you like a hint? (y/n) " hint

if [ $hint == y ] || [ $hint == Y ]; then
    echo "You might need to delete something to relieve the pressure"
fi
