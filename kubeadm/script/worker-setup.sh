#!/bin/bash

echo "===== Kubernetes Worker Setup ====="
echo "This node is ready to join the cluster."
echo ""
echo "Run the kubeadm join command copied from MASTER node."
echo ""
echo "Example:"
echo "sudo kubeadm join <MASTER-IP>:6443 --token <TOKEN> \\"
echo "--discovery-token-ca-cert-hash sha256:<HASH>"
