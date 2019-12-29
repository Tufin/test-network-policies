#!/usr/bin/env bash

echo "empty port opens only specified protocol - expected timeout"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: all-ports
spec:
  podSelector:
    matchLabels:
      run: curl
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector: {}
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: UDP
EOF

! kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" www.google.com
success=$?

exit $success