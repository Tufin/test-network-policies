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

# deploy "hello" service
kubectl create deployment hello --image=gcr.io/hello-minikube-zero-install/hello-node 
kubectl expose deployment hello --type=ClusterIP --port=8080

# create "second" namespace
kubectl create namespace second
kubectl label namespace second namespace=second

# wait for hello pod to be ready
while [[ $(kubectl get pods -l app=hello -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done

for f in test-*.sh; do  
  echo ""
  bash "$f" -H
  AssertSuccess $?
done

# cleanup
kubectl delete service --all
kubectl delete deployment --all
kubectl delete networkpolicy --all
kubectl delete namespace second
