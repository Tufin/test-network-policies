#!/usr/bin/env bash

echo "client in another namespace (default policy allows cross-namespace comms) - expected 200"
kubectl run --namespace second -it --rm --restart=Never curl --image=appropriate/curl --command -- curl --max-time 3 -s -o /dev/null -w "%{http_code}" hello.default.svc.cluster.local:8080
success=$?

exit $success