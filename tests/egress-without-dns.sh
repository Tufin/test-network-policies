#!/usr/bin/env bash

echo "egress without DNS - expected timeout"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default.balance
  namespace: default
spec:
  podSelector:
    matchLabels:
      run: curl
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: hello
  policyTypes:
  - Egress
EOF

! kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
success=$?

exit $success