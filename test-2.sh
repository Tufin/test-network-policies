echo "pods in same namespace (policy doesn't allow) - expected timeout"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default.block-hello
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: hello
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
EOF
! kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
success=$?
kubectl delete networkpolicy default.block-hello

exit $success 