#!/usr/bin/env bash

echo "client in another namespace (deny policy) - expected timeout"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default.deny
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
! kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
success=$?

kubectl delete networkpolicy default.deny

exit $success