#!/bin/bash -e
#
# Create 3 node k3s cluster using multipass to orchestrate
# Ubuntu multipass: https://multipass.run/docs
# K3s - lightweight k8s: https://rancher.com/docs/k3s/latest/en/
#
######################
# MODIFY THIS AS NEEDED
# Names for the VMs in multipass and hostnames (node names)
K8S_MASTER="kube-master"
K8S_WORKER1="kube-worker1"
K8S_WORKER2="kube-worker2"
# specs
K8S_NODEDISKSPACE="5G"
K8S_NODEMEMORY="1G"
K8S_NODECPUS="1"

KUBECONFIG_NAME="k3s-config"
KUBECONFIG_CLUSTERNAME="k3s-cluster"
#####################

echo -e "---\n !!!! K3s MultiNode Cluster K8s Running on Multipass VMs !!!! \n---"

echo -e "1. Creating the kubernetes master (k3s) - $K8S_MASTER ([CPU: $K8S_NODECPUS] [MEM: $K8S_NODEMEMORY] [DISK $K8S_NODEDISKSPACE] )\n----"
# 1. Create the master
multipass launch --name $K8S_MASTER --cpus $K8S_NODECPUS --mem $K8S_NODEMEMORY --disk $K8S_NODEDISKSPACE 18.04 --cloud-init cloud-init/master-cloud-config
K8S_TOKEN=$(multipass exec $K8S_MASTER -- sudo cat /var/lib/rancher/k3s/server/node-token)
echo -e "join token: $K8S_TOKEN \n"
K8S_MASTERIP=$(multipass info $K8S_MASTER --format json | jq -r '.info[].ipv4[]')
echo -e "master node ip: $K8S_MASTERIP \n----"

echo -e "Waiting to ensure master is up and running before proceeding with work nodes ... \n----"
sleep 10

# 2. CONFIGURE worker1 and join it to the cluster
echo -e "2. Creating the kubernetes worker1 and joining to the cluster (k3s) - $K8S_WORKER1 ([CPU: $K8S_NODECPUS] [MEM: $K8S_NODEMEMORY] [DISK $K8S_NODEDISKSPACE] )\n----"
# a. Agent Options to pass to k3s setup script; creates the cloud-init for stdin to multipass
OPTIONS1="K3S_URL=https://${K8S_MASTERIP}:6443 K3S_TOKEN="
OPTIONS1+=$(echo "$K8S_TOKEN" | tr -d '\040\011\012\015') #trim out hidden chars causing issues in sed
#python -c 'import sys; string = sys.stdin.read(); print(string.replace(sys.argv[1],sys.argv[2].strip()))' "K3SOPTIONS" $OPTIONS1 <cloud-init/worker-cloud-config
WORKER1CONFIG=$(sed -e "s/K8S_WORKER/$K8S_WORKER1/" -e "s|K3SOPTIONS|$OPTIONS1|" cloud-init/worker-cloud-config)
echo "Check validity of the YAML cloud-init config..."
echo "$WORKER1CONFIG" | python -c 'import yaml, sys; print(yaml.safe_load(sys.stdin))'
# b. Launch the node vm
echo "----"
echo "$WORKER1CONFIG" | multipass launch --name $K8S_WORKER1 --cpus $K8S_NODECPUS --mem $K8S_NODEMEMORY --disk $K8S_NODEDISKSPACE  18.04 --cloud-init -
echo "----"

# 3. CONFIGURE worker2 and join it to the cluster
echo -e "3. Creating the kubernetes worker2 and joining to the cluster (k3s) - $K8S_WORKER2 ([CPU: $K8S_NODECPUS] [MEM: $K8S_NODEMEMORY] [DISK $K8S_NODEDISKSPACE] )\n----"
# a. Agent Options to pass to k3s setup script; creates the cloud-init for stdin to multipass
OPTIONS2="K3S_URL=https://${K8S_MASTERIP}:6443 K3S_TOKEN="
OPTIONS2+=$(echo "$K8S_TOKEN" | tr -d '\040\011\012\015') #trim out hidden chars causing issues in sed
#python -c 'import sys; string = sys.stdin.read(); print(string.replace(sys.argv[1],sys.argv[2].strip()))' "K3SOPTIONS" $OPTIONS2 <cloud-init/worker-cloud-config
WORKER2CONFIG=$(sed -e "s/K8S_WORKER/$K8S_WORKER2/" -e "s|K3SOPTIONS|$OPTIONS2|" cloud-init/worker-cloud-config)
echo "Check validity of the YAML cloud-init config..."
echo "$WORKER2CONFIG" | python -c 'import yaml, sys; print(yaml.safe_load(sys.stdin))'
# b. Launch the node vm
echo "----"
echo "$WORKER2CONFIG" | multipass launch --name $K8S_WORKER2 --cpus $K8S_NODECPUS --mem $K8S_NODEMEMORY --disk $K8S_NODEDISKSPACE  18.04 --cloud-init -
echo "----"

echo -e "DONE!! Below are the current multipass VM nodes:\n----"
multipass list
echo -e "----\nWaiting 10 seconds and will 'exec' in multipass to check nodes from the master in a kubectl watch; you should see 3 nodes ...\n----"
sleep 10
multipass exec $K8S_MASTER -- kubectl get nodes
echo -e "----\nRun 'multipass shell $K8S_MASTER' to shell in and use kubectl."
echo "----"
echo "Copying the k3s kube config to $HOME at ~/.kube/k3s-config"


if [ -d ~/.kube ]; then
    multipass copy-files $K8S_MASTER:/etc/rancher/k3s/k3s.yaml ~/.kube/$KUBECONFIG_NAME
else
    mkdir ~/.kube
    multipass copy-files $K8S_MASTER:/etc/rancher/k3s/k3s.yaml ~/.kube/$KUBECONFIG_NAME
fi

sed -i -e "s|server: https://127.0.0.1:6443|server: https://$K8S_MASTERIP:6443|" \
-e "s|cluster: default|cluster: $KUBECONFIG_CLUSTERNAME|" \
-e "s|name: default|name: $KUBECONFIG_CLUSTERNAME|" \
-e "s|- name: $KUBECONFIG_CLUSTERNAME|- name: default|" \
-e "s|current-context: default|current-context: $KUBECONFIG_CLUSTERNAME|" \
 ~/.kube/$KUBECONFIG_NAME

echo -e "configuration file is named: $KUBECONFIG_NAME and is located ~/.kube/ \n You can now use your local kubectl to access the clusterIP (IP: $K8S_MASTERIP)"
echo "----"
echo -e "Add 'export KUBECONFIG=$KUBECONFIG:~/.kube/config:~/.kube/$KUBECONFIG_NAME' to your ~/.bashrc or ~/.zshrc \nOR run kubectl with the '--kubeconfig flag (e.g. kubectl --kubeconfig ~/.kube/$KUBECONFIG_NAME get nodes)"
echo "----"
echo "All DONE - Enjoy!"

# whatever is put in  k8s/default/ will be deployed
#multipass copy-files k8s/default/deployment.yaml kube-master:/var/lib/rancher/k3s/server/manifests/custom/deployment.yaml
#
