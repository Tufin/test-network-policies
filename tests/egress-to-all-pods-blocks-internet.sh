#!/usr/bin/env bash

echo "egress to all pods, prohibits access to the internet - expected timeout"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-all-pods
spec:
  podSelector: {}
  egress:
  - to:
    - podSelector: {}
  policyTypes:
  - Egress
EOF

! kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" www.google.com
success=$?

exit $success