# 🚀 Kubernetes Cluster Setup on Ubuntu 24.04 LTS using kubeadm (AWS EC2)

![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.30-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-orange)
![AWS](https://img.shields.io/badge/AWS-EC2-yellow)
![containerd](https://img.shields.io/badge/ContainerRuntime-containerd-green)
![CNI](https://img.shields.io/badge/CNI-Calico-purple)

---

## 📘 Overview

This blog explains **how to install a Kubernetes cluster using kubeadm** on **Ubuntu 24.04 LTS** running on **AWS EC2 instances**.

This method is recommended for:

* DevOps beginners
* Kubernetes internal learning
* Training & lab practice
* Interview preparation

---

## 📑 Table of Contents

1. Prerequisites
2. Kubernetes Architecture
3. Set Hostnames
4. Disable Swap
5. Enable Kernel Modules
6. Configure Networking
7. Install containerd (Important Fix)
8. Install Kubernetes Components
9. Initialize Kubernetes Cluster
10. Configure kubectl
11. Install Calico Network
12. Join Worker Node
13. Validation
14. Common Errors & Fixes
15. Cleanup
16. Conclusion

---

## 📌 Prerequisites

* AWS EC2 instances with **Ubuntu 24.04 LTS**
* Minimum configuration:

  * Master: 2 vCPU, 2 GB RAM
  * Worker: 1 vCPU, 2 GB RAM
* All instances in **same VPC**
* Security Group ports:

  * SSH → `22`
  * Kubernetes API → `6443`
  * Kubelet → `10250`
  * NodePort → `30000–32767`

---

## 🧱 Kubernetes Architecture

![Image](https://miro.medium.com/1%2Ayq0bky23otUFDU1DbUftGg.png)

![Image](https://kubernetes.io/images/docs/components-of-kubernetes.svg)

A Kubernetes cluster consists of:

* **Control Plane (Master Node)**
  Manages API server, scheduler, controller manager, etcd
* **Worker Nodes**
  Run application pods

We use **Kubernetes kubeadm** to bootstrap the cluster safely and correctly.

---

## 🔹 Step 1: Set Hostnames (All Nodes)

### Command

```bash
sudo hostnamectl set-hostname k8s-master
exit
```

### Explanation

* `hostnamectl` sets a unique hostname
* Kubernetes uses hostname to identify nodes
* `exit` logs out so hostname refreshes

Repeat on worker:

```bash
sudo hostnamectl set-hostname k8s-worker-1
exit
```

---

## 🔹 Step 2: Disable Swap (All Nodes)

Kubernetes **does not support swap memory**.

### Disable swap immediately

```bash
sudo swapoff -a
```

### Disable swap permanently

```bash
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### Verify

```bash
sudo free -h
```

📌 Swap should show **0B**

---

## 🔹 Step 3: Enable Required Kernel Modules

Kubernetes networking requires specific Linux kernel modules.

### Load modules

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

### Persist modules after reboot

```bash
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
```

### Explanation

* `overlay` → container filesystem support
* `br_netfilter` → enables iptables for pod traffic

---

## 🔹 Step 4: Configure System Networking

### Apply sysctl settings

```bash
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```

### Reload settings

```bash
sudo sysctl --system
```

### Explanation

* Enables pod-to-pod communication
* Enables service routing
* Mandatory for Kubernetes networking

---

## 🔹 Step 5: Install Container Runtime (containerd)

⚠️ **IMPORTANT FIX for Ubuntu 24.04**

### Install containerd

```bash
sudo apt update
sudo apt install -y containerd
```

### 🔴 Common Error (Students Face)

```
sed: can't read /etc/containerd/config.toml: No such file or directory
```

### 🧠 Why This Happens

* Ubuntu 24.04 **does not create config.toml by default**
* You must generate it manually

---

### ✅ Correct Fix (Mandatory)

#### Create containerd config file

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

#### Enable systemd cgroup (Required by Kubernetes)

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

#### Restart containerd

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
```

#### Verify

```bash
sudo systemctl status containerd
```

Expected:

```
Active: active (running)
```

---

## 🔹 Step 6: Install Kubernetes Components

### Install dependencies

```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg
```

### Add Kubernetes GPG key

```bash
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
| sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

### Add Kubernetes repository

```bash
sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /
EOF
```

### Install tools

```bash
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
```

### Lock versions

```bash
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 🔹 Step 7: Initialize Kubernetes Cluster (Master Only)

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

### Explanation

* Bootstraps control plane
* Creates certificates
* Starts API server on port `6443`
* CIDR required for Calico network

⚠️ **Save the kubeadm join command**

---

## 🔹 Step 8: Configure kubectl (Master)

```bash
sudo mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Explanation

* kubectl needs credentials to access cluster
* Without this, kubectl tries `127.0.0.1:8080` and fails

Verify:

```bash
sudo kubectl get nodes
```

---

## 🔹 Step 9: Install Pod Network (Calico)

```bash
sudo kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Explanation

* Kubernetes has **no default networking**
* Calico provides:

  * Pod IP assignment
  * Pod-to-pod communication
  * Network policies

Verify:

```bash
sudo kubectl get pods -n kube-system
```

---

## 🔹 Step 10: Join Worker Node

```bash
sudo kubeadm join <MASTER-IP>:6443 --token <TOKEN> \
--discovery-token-ca-cert-hash sha256:<HASH>
```

### Explanation

* Registers worker with master
* Starts kubelet
* Worker becomes schedulable

---

## ✅ Final Validation

```bash
sudo kubectl get nodes
sudo kubectl get pods -A
```

Expected:

* All nodes → **Ready**

---

## 🛠 Common Errors & Fixes

### ❌ Error

```
dial tcp 127.0.0.1:8080: connect: connection refused
```

### ✅ Fix

```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
```

Reconfigure kubectl and retry.

---

## 🧹 Cleanup (Optional)

```bash
sudo kubeadm reset -f
```

---

## 🎯 Conclusion

You have successfully:

* Installed Kubernetes on **Ubuntu 24.04 LTS**
* Used **kubeadm + containerd**
* Fixed real-world containerd issues
* Built a **production-style learning cluster**

---

### 👨‍🏫 Author

**Rushikesh N (Rushi)**
DevOps & Cloud Trainer | AWS | Kubernetes

