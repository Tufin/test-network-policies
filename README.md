# test-network-policies
This repo contains a set of tests for Kubernetes network policies.  
test-netpol.sh sets up a 'hello' pod and service in namespace default and a second namespace 'second'.  
Then, each test script under tests applies some network policy and runs a client pod to test that connectivity succeeds or fails according to expected behavior.

## Setting up a cluster
Before running the tests, setup a cluster with **network policies enabled**.  
Note that GKE disables network policies by default.

## Connecting to the cluster
Make sure you are connected to your cluster as cluster admin.  
`kubectl` should be able to create pods, services and network policies.

## Running the tests

Run all tests:
```
./test-netpol.sh
```

You should "SUCCESS" after each test.
If you see "FAIL" then something went wrong.  
If you think its a bug, please submit an issue with the kubernetes and CNI platform/version details, and the failing test.

Run a single test:
```
# pass relative path to test file as argument
./test-netpol.sh tests/alllow-all-without-internet.sh 
```

## Learning about network policies
See my Medium article   :  
https://medium.com/@reuvenharrison/an-introduction-to-kubernetes-network-policies-for-security-people-ba92dd4c809d

## Tufin SecureCloud
I wrote these tests while developing SecureCloud which is a Kubernetes security solution.  
I welcome you to try SecureCloud on your own cluster and share your feedback:  
https://www.tufin.com/tufin-orchestration-suite/securecloud#jump-form