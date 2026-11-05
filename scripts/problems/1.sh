#!/bin/bash
#Web-app down

MainDir=asdf
IP=$(grep workload_node_ip $MainDir/connection_info | cut -d'"' -f2)
WKC=$MainDir/tf/aws/kube_config_workload.yaml

kubectl --kubeconfig $WKC taint nodes --all appworks=false:NoSchedule
kubectl --kubeconfig $WKC apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: custom-web
    workload.user.cattle.io/workloadselector: apps.deployment-default-custom-web
  name: custom-web
  namespace: default
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      workload.user.cattle.io/workloadselector: apps.deployment-default-custom-web
  strategy:
    type: Recreate
  template:
    metadata:
      annotations:
      labels:
        app: custom-web
        workload.user.cattle.io/workloadselector: apps.deployment-default-custom-web
      name: custom-web
      namespace: default
    spec:
      affinity: {}
      containers:
      - image: nginx
        imagePullPolicy: Always
        name: nginx
        ports:
        - containerPort: 80
          name: 80tcp
          protocol: TCP
        resources:
          limits:
            memory: 33Gi
          requests:
            cpu: "10"
            memory: 256Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: html-volume
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
      - configMap:
          defaultMode: 420
          name: web-page-config
        name: html-volume
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-app
  namespace: default
spec:
  ingressClassName: traefik
  rules:
  - host: app.$IP.nip.io
    http:
      paths:
      - backend:
          service:
            name: custom-web
            port:
              number: 80
        path: /
        pathType: Prefix
status:
  loadBalancer: {}
---
apiVersion: v1
kind: Service
metadata:
  name: custom-app
  namespace: default
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: custom-web
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-page-config
  namespace: default
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Troublemaker Lab</title>
      <style>
        body { font-family: sans-serif; text-align: center; margin-top: 10%; background-color: #f4f4f9; }
        h1 { color: #326ce5; }
    </style>
    </head>
    <body>
      <h1>Congrats on fixing the Rancher Troublemaker Lab
    </body>
    </html>
EOF

echo "Our Web App at app.$IP.nip.io is failing to serve content. Please get it fixed."
