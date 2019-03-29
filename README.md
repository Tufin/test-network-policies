# test-network-policies
Testing Kubernetes network policies behavior

Before running the tests, setup minikube with calico:
```
minikube start --memory 4096 --network-plugin=cni
curl -O -L https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
sed -i -e '/nodeSelector/d' calico.yaml
sed -i -e '/node-role.kubernetes.io\/master: ""/d' calico.yaml
kubectl apply -f calico.yaml
kubectl get node
```
Wait till it is ready...

Run all tests:
```
./test_netpol.sh
```
