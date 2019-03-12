#!/usr/bin/env bash

echo "pods in same ns (no policy) - expected 200"
kubectl create deployment hello --image=gcr.io/hello-minikube-zero-install/hello-node 
kubectl expose deployment hello --type=ClusterIP --port=8080
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi

echo "pods in same ns (block policy) - expected timeout"
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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -eq 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy default.block-hello

echo "add an allow-all policy to override the more specific one - expected 200"
cat <<EOF | kubectl create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-all
  namespace: default
spec:
  podSelector: {}
  ingress:
  - {}
  policyTypes:
  - Ingress
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy allow-all


echo "pods in same ns (allow policy) - expected 200"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default.allow-hello
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
          run: curl
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy default.allow-hello

echo "client in another ns (default policy allows cross-namespace comms) - expected 200"
kubectl create namespace second
kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi

echo "client in another ns (deny policy) - expected timeout"
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
kubectl label namespace second namespace=second
kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
if [ $? -eq 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy default.deny
kubectl label namespace second namespace-

echo "policy with OR (using two froms) - expected 200"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default.postgres
  namespace: default
spec:
  ingress:
  - from:
    - podSelector:
        matchLabels:
          run: curl1
  - from:
    - podSelector:
        matchLabels:
          run: curl2
  podSelector:
    matchLabels:
      app: hello
  policyTypes:
  - Ingress
EOF
kubectl run -it --rm --restart=Never curl1 --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl run -it --rm --restart=Never curl2 --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy default.postgres

echo "policy with OR (using two podSelectors) - expected 200"
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default.postgres
  namespace: default
spec:
  ingress:
  - from:
    - podSelector:
        matchLabels:
          run: curl1
    - podSelector:
        matchLabels:
          run: curl2
  podSelector:
    matchLabels:
      app: hello
  policyTypes:
  - Ingress
EOF
kubectl run -it --rm --restart=Never curl1 --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl run -it --rm --restart=Never curl2 --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy default.postgres


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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -eq 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy default.balance

echo "egress with DNS - expected 200"
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
  - to:
    ports:
    - protocol: UDP
      port: 53
  policyTypes:
  - Egress
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy default.balance

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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy default.balance
kubectl label namespace kube-system namespace-

echo "deny all policy - expected timeout"
cat <<EOF | kubectl create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -eq 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy deny-all

echo "allow all from the same namespace - expected 200"
cat <<EOF | kubectl create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-all
  namespace: default
spec:
  podSelector: {}
  ingress:
  - {}
  policyTypes:
  - Ingress
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi

echo "allow all from another namespace - expected 200"
kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy allow-all

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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 10 -s -o /dev/null -w "%{http_code}" hello:8080
if [ $? -ne 0 ]; then
  echo "### FAIL ###"
else
  echo "### SUCCESS ###"
fi
kubectl delete networkpolicy allow-all-to-hello


#kubectl run -it --rm --restart=Never busybox --image=busybox wget svc1:8080
#kubectl run -it --rm --restart=Never curl --image=giantswarm/tiny-tools curl http://hello-node:8080

# cleanup
kubectl delete service --all
kubectl delete deployment --all
#kubectl delete pod --all
kubectl delete networkpolicy --all
kubectl delete namespace second
