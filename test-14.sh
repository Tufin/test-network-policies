#!/usr/bin/env bash

echo "egress all, allows access to the internet - expected 200"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-egress
  namespace: default
spec:
  podSelector: {}
  egress:
  - {}
  policyTypes:
  - Egress
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" www.google.com
success=$?

kubectl delete networkpolicy allow-all-egress

exit $success