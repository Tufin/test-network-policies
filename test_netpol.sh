#!/usr/bin/env bash

AssertSuccess () {
  if [ $? -ne 0 ]; then
    echo "############"
    echo "### FAIL ###"
    echo "############"
  else
    echo "SUCCESS"
  fi
}

AssertFailure () {
  if [ $? -eq 0 ]; then
    echo "############"
    echo "### FAIL ###"
    echo "############"
  else
    echo "SUCCESS"
  fi
}

# deploy client and service
kubectl create deployment hello --image=gcr.io/hello-minikube-zero-install/hello-node 
kubectl expose deployment hello --type=ClusterIP --port=8080

while [[ $(kubectl get pods -l app=hello -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done


echo ""
########################################################################################
echo "pods in same namespace (no policy) - expected 200"
########################################################################################
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess

echo ""
########################################################################################
echo "pods in same namespace (block policy) - expected timeout"
########################################################################################
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

AssertFailure
kubectl delete networkpolicy default.block-hello

echo ""
########################################################################################
echo "add an allow-all policy to override the more specific one - expected 200"
########################################################################################
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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess
kubectl delete networkpolicy allow-all

echo ""
########################################################################################
echo "pods in same namespace (allow policy) - expected 200"
########################################################################################
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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess
kubectl delete networkpolicy default.allow-hello

echo ""
########################################################################################
echo "client in another namespace (default policy allows cross-namespace comms) - expected 200"
########################################################################################
kubectl create namespace second
kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
AssertSuccess

echo ""
########################################################################################
echo "client in another namespace (deny policy) - expected timeout"
########################################################################################
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
kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
AssertFailure
kubectl delete networkpolicy default.deny
kubectl label namespace second namespace-

echo ""
########################################################################################
echo "policy with OR (using two froms) - expected 200"
########################################################################################
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
kubectl run -it --rm --restart=Never curl1 --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess

kubectl run -it --rm --restart=Never curl2 --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess

kubectl delete networkpolicy default.postgres

echo ""
########################################################################################
echo "policy with OR (using two podSelectors) - expected 200"
########################################################################################
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
kubectl run -it --rm --restart=Never curl1 --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess

kubectl run -it --rm --restart=Never curl2 --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess

kubectl delete networkpolicy default.postgres

echo ""
########################################################################################
echo "egress without DNS - expected timeout"
########################################################################################
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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertFailure
kubectl delete networkpolicy default.balance

echo ""
########################################################################################
echo "egress with DNS - expected 200"
########################################################################################
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
    - protocol: UDP
      port: 54 # open 54 too in case tufindns is installed
  policyTypes:
  - Egress
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess
kubectl delete networkpolicy default.balance

echo ""
########################################################################################
echo "egress with a specific DNS policy - expected 200"
########################################################################################
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
AssertSuccess
kubectl delete networkpolicy default.balance
kubectl label namespace kube-system namespace-

echo ""
########################################################################################
echo "egress all, allows access to the internet - expected 200"
########################################################################################
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
AssertSuccess
kubectl delete networkpolicy allow-all-egress

echo ""
########################################################################################
echo "egress to all pods, prohibits access to the internet - expected timeout"
########################################################################################
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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" www.google.com
AssertFailure
kubectl delete networkpolicy allow-egress-all-pods

echo ""
########################################################################################
echo "deny all policy - expected timeout"
########################################################################################
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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertFailure
kubectl delete networkpolicy deny-all

echo ""
########################################################################################
echo "allow all from the same namespace - expected 200"
########################################################################################
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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess

echo ""
########################################################################################
echo "allow all from another namespace - expected 200"
########################################################################################
kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
AssertSuccess
kubectl delete networkpolicy allow-all

echo ""
########################################################################################
echo "allow all to a specific namespace - expected 200"
########################################################################################
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
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
AssertSuccess
kubectl delete networkpolicy allow-all-to-hello

echo ""
########################################################################################
echo "allow egress to any pod, but external IPs are still blocked - expected timeout"
########################################################################################
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: foo-deny-external-egress
spec:
  podSelector:
    matchLabels:
      run: curl
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - port: 53
      protocol: UDP
    - port: 54
      protocol: UDP
    - port: 80
      protocol: TCP
  - to:
    - namespaceSelector: {}
EOF
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" www.google.com
AssertFailure
kubectl delete networkpolicy foo-deny-external-egress


# cleanup
echo ""
kubectl delete service --all
kubectl delete deployment --all
kubectl delete networkpolicy --all
kubectl delete namespace second
