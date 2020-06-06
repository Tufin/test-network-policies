#!/usr/bin/env bash

echo "test ping (not tcp, nor udp) - expected 1"
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
    ports:
    - protocol: TCP
    - protocol: UDP
EOF

! kubectl run  -it --rm --restart=Never ping --image=busybox --command -- ping -c1 8.8.8.8
success=$?

exit $success