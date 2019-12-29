# test-network-policies
Testing Kubernetes network policies behavior

Before running the tests, setup a cluster with network policies enabled

Run all tests:
```
./test_netpol.sh
```

Run specific test:
```
# pass relative path to test file as argument
./test_netpol.sh tests/alllow-all-without-internet.sh 
```
