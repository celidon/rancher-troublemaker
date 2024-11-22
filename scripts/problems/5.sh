#!/bin/bash
#Bad CA replacement

MainDir=asdf
RKC=$MainDir/tf/aws/kube_config_server.yaml
RANCHER_URL=$(grep url $MainDir/connection_info | cut -d'"' -f2 | cut -d/ -f3)

#openssl commands
openssl genrsa -out rootCA1.key.pem -aes256 -passout pass: &>/dev/null
mydn="/C=US/ST=SUSE/L=Rancher/O=Rancher TroubleMaker/OU=Problems/CN=TroubleMaker CA Root"
openssl req -new -x509 -key rootCA1.key.pem -passin pass: -subj "${mydn}" -days 365 -out cacert.pem &>/dev/null
openssl req -new -nodes -out tls.csr -newkey rsa:4096 -keyout tls.key -subj "/CN=$RANCHER_URL/C=US/ST=SUSE/L=Rancher/O=Rancher Troublemaker/OU=Problems" &>/dev/null
openssl x509 -req -in tls.csr -CA cacert.pem -CAkey rootCA1.key.pem -CAcreateserial -out tls.crt -days 730 -sha256 -passin pass: -extfile <(printf "subjectAltName=DNS:$RANCHER_URL") &>/dev/null

#kubectl $RKC commands
kubectl --kubeconfig $RKC -n cattle-system create secret tls tls-rancher-ingress --cert=tls.crt --key=tls.key --dry-run --save-config -o yaml 2>/dev/null | kubectl --kubeconfig $RKC apply -f - &>/dev/null
kubectl --kubeconfig $RKC -n cattle-system create secret generic tls-ca --from-file=cacert.pem --dry-run --save-config -o yaml 2>/dev/null | kubectl --kubeconfig $RKC apply -f - &>/dev/null

#Helm commands
helm --kubeconfig $RKC get values -n cattle-system rancher 2>/dev/null > values.yaml
cat >> values.yaml << EOF
ingress:
  tls:
    source: secret
privateCA: true
EOF
helm repo add rancher-prime https://charts.rancher.com/server-charts/prime &>/dev/null
helm repo update &>/dev/null
helm --kubeconfig $RKC upgrade rancher rancher-prime/rancher -n cattle-system -f values.yaml --version 2.9.3 &>/dev/null

CA_CHECKSUM=$(sha256sum cacert.pem | cut -d" " -f1)
sed -i "s|CA_CHECKSUM=.*$|CA_CHECKSUM=$CA_CHECKSUM|" $MainDir/scripts/checks/5.sh
rm values.yaml tls* *.pem *.srl

echo -e "Something went wrong while moving to a certificate with a private CA.\nThe Rancher pod isn't starting after step 3 from https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/resources/update-rancher-certificate\nOnce that is fixed, downstream needs to be connected."
