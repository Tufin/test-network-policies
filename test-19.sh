#!/usr/bin/env bash

echo "allow all to a specific namespace - expected 200"
cat <<EOF | kubectl create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-all-to-hello
  namespace: default
spec:
  podSelector:
      matchLabels:
        app: hello
  ingress:
  - {}
  policyTypes:
  - Ingress
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
success=$?

kubectl delete networkpolicy allow-all-to-hello

exit $success