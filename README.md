# test-network-policies
Testing Kubernetes network policies behavior

Before running the tests:
```
minikube start --memory 4096 --network-plugin=cni
curl -O -L https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
sed -i -e '/nodeSelector/d' calico.yaml
sed -i -e '/node-role.kubernetes.io\/master: ""/d' calico.yaml
kubectl apply -f calico.yaml
kubectl get node (wait till it is ready)
```

Using calicoctl:
```
minikube ssh
sudo curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.5.1/calicoctl
sudo chmod +x calicoctl
ETCD_ENDPOINTS=http://0.0.0.0:6666 calicoctl get globalNetworkPolicy -o yaml
```