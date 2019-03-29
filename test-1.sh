#!/usr/bin/env bash

echo "pods in same namespace (no policy) - expected 200"
kubectl run -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello:8080
success=$?
exit $success
