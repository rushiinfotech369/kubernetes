#!/bin/bash

echo "===== Kubernetes Master Setup Started ====="

# Initialize Kubernetes cluster
echo "Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Configure kubectl for current user
echo "Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Remove proxy variables if any
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

# Install Calico network plugin
echo "Installing Calico network..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "===== Master Setup Completed ====="
echo "IMPORTANT: Save the kubeadm join command from above output"
