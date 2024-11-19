#!/bin/bash
#RKE2 Downstream uninstalled

MainDir=asdf
IP=$(grep workload_node_ip $MainDir/connection_info | cut -d'"' -f2)
SSH="ssh ec2-user@$IP -i $MainDir/id_rsa -o StrictHostKeyChecking=no -C sudo"

kubectl --kubeconfig=$MainDir/tf/aws/kube_config_workload.yaml apply -f https://raw.githubusercontent.com/skynet86/hello-world-k8s/refs/heads/master/hello-world.yaml > /dev/null

sleep 5

$SSH rke2 etcd-snapshot save --etcd-snapshot-dir /home/ec2-user &> /dev/null
snapshot=$($SSH ls on-demand*)
sed -i "s|SNAPSHOT=.*$|SNAPSHOT=$snapshot|" $MainDir/scripts/checks/2.sh 
$SSH rke2-uninstall.sh &> /dev/null

echo "RKE2 isn't working on the downstream cluster. Please get the app back online. The node cannot be replaced. There is a snpshot on the node."
