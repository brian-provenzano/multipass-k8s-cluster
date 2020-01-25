# Multipass Ubuntu + K3s = Lightweight K8s goodness

Simple project (shell script) to launch a 3 node kubernetes cluster on multipass VMs using k3s.

Useful as a lightweight local multinode lab k8s playground (e.g. replacement for MacOS K8s in Docker Desktop / KIND which is only single node).

Will also pull down the k3s kubeconfig from the k8s master using multipass copy-files and install in `~/.kube` as `k3s-config` (can be changed in the script) so you can access the cluster from your host.

Tested on MacOS / Linux; currently uses Ubuntu 18.04 LTS for node images

<a href="https://asciinema.org/a/l3t6QSfjZmfCRjQoZ8UuAoKTj?speed=20&theme=solarized-dark" target="_blank"><img src="https://asciinema.org/a/l3t6QSfjZmfCRjQoZ8UuAoKTj.svg" width=900 height=700 /></a>

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

NOTE: When stopping or destroying you may get these messages ` [error] [kube-worker2] process error occurred Crashed`.  These can be ignored.  Seems to be an issue with multipass, but the VMs are cleaned up and stopped.


## Directory description

 - cloud-init - contains cloud-init scripts used to boot/configure the nodes (install k3s, config for k8s etc)
 - k8s - contains sample deployment to try


## License
Do as you want "AS-IS" code.
