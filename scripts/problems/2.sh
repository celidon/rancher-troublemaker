#!/bin/bash
#RKE2 Downstream uninstalled

SSH="ssh ec2-user@54.82.191.43 -i $MainDir/id_rsa -C sudo"

kubectl --kubeconfig=$MainDir/tf/aws/kube_config_workload.yaml apply -f https://raw.githubusercontent.com/skynet86/hello-world-k8s/refs/heads/master/hello-world.yaml > /dev/null

sleep 5

$SSH rke2 etcd-snapshot save --etcd-snapshot-dir /home/ec2-user &> /dev/null
snapshot=$($SSH ls on-demand*)
sed -i "s/SNAPSHOT=/SNAPSHOT=$snapshot/" $MainDir/scripts/checks/2.sh > /dev/null
$SSH rke2-uninstall.sh &> /dev/null

echo "RKE2 isn't working on the downstream cluster. Please get the app back online. The node cannot be replaced"
