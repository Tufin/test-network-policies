#!/usr/bin/env bash

echo "test ping (not tcp, nor udp) - expected 0"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: all-ports
spec:
  podSelector:
    matchLabels:
      run: ping
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector: {}
    - ipBlock:
        cidr: 8.8.8.8/32
EOF

kubectl run  -it --rm --restart=Never ping --image=busybox --command -- ping -c1 8.8.8.8
success=$?

exit $success