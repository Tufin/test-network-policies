#!/usr/bin/env bash

echo "egress with a specific DNS policy - expected 200"

kubectl label namespace kube-system namespace=k8s

cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default.balance
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: balance
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
  - to:
    - namespaceSelector:
        matchLabels:
          namespace: k8s
    ports:
    - protocol: UDP
      port: 53
  policyTypes:
  - Egress
EOF

kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
success=$?

kubectl label namespace kube-system namespace-

exit $success