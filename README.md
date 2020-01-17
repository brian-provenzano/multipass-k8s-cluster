# Multipass Ubuntu + K3s equals goodness

Simple project (mostly as shell script) to launch a 3 node kubernetes cluster on multipass VMs using k3s.  Useful as a multinode replacement for MacOS K8s in Docker Desktop.  

Will also pull down the k3s kubeconfig from the k8s master using multipass copy-files and install in `~/.kube` as `k3s-config` (can be changed in the script) so you can access the cluster from your host.

Tested on MacOS / Linux; currently uses Ubuntu 18.04 LTS for node images

K3s:
 - https://k3s.io/
 - https://rancher.com/docs/k3s/latest/en/
 - https://github.com/rancher/k3s/blob/master/README.md


Multipass:
- https://multipass.run/docs


## Usage

1. To create a cluster, clone this repo and adjust the `create.sh` as needed and run it

```
./create.sh
```

2. To start, stop, destroy the cluster (via multipass) see `stop.sh`, `start.sh`, `destroy.sh` - extend or modify these scripts as needed


## Directory description

 - cloud-init - contains cloud-init scripts used to boot/configure the nodes (install k3s, config for k8s etc)
 - k8s - contains sample deployment to try


## License
Do as you want "AS-IS" code.
