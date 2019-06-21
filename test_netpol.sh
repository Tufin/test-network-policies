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
  for ns in $(kubectl get ns -o jsonpath="{.items[*].metadata.name}"); do
    for np in $(kubectl get networkpolicies --namespace $ns -o jsonpath="{.items[*].metadata.name}"); do
      kubectl delete networkpolicies $np
    done
  done
}

if [ "$1" != "" ]; then
  test_file=$1
fi

echo ""
echo "deploying 'hello' service ..."
kubectl create deployment hello --image=gcr.io/hello-minikube-zero-install/hello-node 
kubectl expose deployment hello --type=ClusterIP --port=8080

echo ""
echo "creating 'second' namespace ..."
kubectl create namespace second
kubectl label namespace second namespace=second

echo ""
echo "waiting for hello pod to be ready..."
while [[ $(kubectl get pods -l app=hello -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done

echo ""
echo "running tests..."
for f in test-*.sh; do  
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
kubectl delete service --all
kubectl delete deployment --all
kubectl delete networkpolicy --all
kubectl delete namespace second
