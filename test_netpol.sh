#!/usr/bin/env bash

AssertSuccess () {
  if [ $1 -ne 0 ]; then
    echo "############"
    echo "### FAIL ###"
    echo "############"
  else
    echo "SUCCESS"
  fi
}

CleanupNetworkPolicies () {
  for ns in $(kubectl get namespace -o jsonpath="{.items[*].metadata.name}"); do
    for np in $(kubectl get networkpolicies --namespace $ns -o jsonpath="{.items[*].metadata.name}"); do
      kubectl delete networkpolicies $np --namespace $ns
    done
  done
}

if [ "$1" != "" ]; then
  test_file=$1
fi

echo ""
echo "deleting any leftover 'curl' pods..."
kubectl delete pod curl

echo ""
echo "resetting network policies..."
CleanupNetworkPolicies

echo ""
echo "creating 'hello' deployment..."
cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: hello
  name: hello
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - image: gcr.io/hello-minikube-zero-install/hello-node
        imagePullPolicy: Always
        name: hello-node
        ports:
        - containerPort: 8080
          name: http
EOF

echo ""
echo "creating 'hello' and service..."
kubectl expose deployment hello --type=ClusterIP --port=8080 --target-port=http 

echo ""
echo "creating 'second' namespace..."
kubectl create namespace second
kubectl label namespace second namespace=second

echo ""
echo "waiting for hello pod to be ready..."
while [[ $(kubectl get pods -l app=hello -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done

echo ""
echo "running tests..."
for f in tests/*; do  
  if [ "$test_file" = "" ] || [ "$f" = "$test_file" ]; then
    echo ""
    echo "$f"
    bash "$f" -H
    AssertSuccess $?
    CleanupNetworkPolicies
  fi
done

echo ""
echo "cleaning up..."
kubectl delete service hello
kubectl delete deployment hello
kubectl delete namespace second


