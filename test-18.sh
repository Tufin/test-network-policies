#!/usr/bin/env bash

echo "default behavior allows all from another namespace - expected 200"
kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
success=$?

kubectl delete networkpolicy allow-all

exit $success