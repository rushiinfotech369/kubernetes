You’re absolutely right 👍
For **students + GitHub readers**, **command explanations are mandatory**.
Below is a **FINAL ENHANCED VERSION** where **every step has clear explanations**, written in **simple trainer-style language**.

👉 This is **ready for GitHub**, **Udemy notes**, and **class labs**.

You can **replace your existing `.md` with this version**.

---

# 🚀 Kubernetes Cluster Setup on Ubuntu 24.04 LTS using kubeadm (AWS EC2)

![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.30-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-orange)
![AWS](https://img.shields.io/badge/AWS-EC2-yellow)
![containerd](https://img.shields.io/badge/ContainerRuntime-containerd-green)
![CNI](https://img.shields.io/badge/CNI-Calico-purple)

---

## 📘 Overview

This guide explains **how to install a Kubernetes cluster using kubeadm** on **Ubuntu 24.04 LTS** running on **AWS EC2**.

This method is widely used for:

* Learning Kubernetes internals
* DevOps training & labs
* Interview preparation
* Self-managed clusters

---

## 📑 Table of Contents

1. Prerequisites
2. Kubernetes Architecture
3. Set Hostnames
4. Disable Swap
5. Enable Kernel Modules
6. Configure Networking
7. Install containerd
8. Install Kubernetes Components
9. Initialize Cluster
10. Configure kubectl
11. Install Calico Network
12. Join Worker Node
13. Validation
14. Troubleshooting
15. Cleanup
16. Conclusion

---

## 📌 Prerequisites

* Ubuntu **24.04 LTS** EC2 instances
* Same VPC & Security Group
* Open ports:

  * `22` (SSH)
  * `6443` (Kubernetes API)
  * `10250` (kubelet)
  * `30000–32767` (NodePort)

---

## 🧱 Kubernetes Architecture

![Image](https://miro.medium.com/1%2Ayq0bky23otUFDU1DbUftGg.png)

![Image](https://kubernetes.io/images/docs/components-of-kubernetes.svg)

A Kubernetes cluster has:

* **Control Plane (Master)** → manages cluster
* **Worker Nodes** → run application pods

We use **Kubernetes kubeadm** to bootstrap the cluster.

---

## 🔹 Step 1: Set Hostnames (All Nodes)

### Command

```bash
sudo hostnamectl set-hostname k8s-master
exit
```

### Explanation

* `hostnamectl` → sets system hostname
* Unique hostnames help Kubernetes identify nodes
* `exit` → logout so hostname refreshes

Repeat on worker:

```bash
sudo hostnamectl set-hostname k8s-worker-1
exit
```

---

## 🔹 Step 2: Disable Swap (All Nodes)

### Command

```bash
sudo swapoff -a
```

### Explanation

* Kubernetes needs full control over memory
* Swap can cause unpredictable pod behavior

Disable swap permanently:

```bash
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

Verify:

```bash
sudo free -h
```

---

## 🔹 Step 3: Enable Required Kernel Modules

### Command

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

### Explanation

* `overlay` → required for container filesystem
* `br_netfilter` → allows iptables to see container traffic

Persist modules:

```bash
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
```

---

## 🔹 Step 4: Configure System Networking

### Command

```bash
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```

Apply:

```bash
sudo sysctl --system
```

### Explanation

* Enables pod-to-pod communication
* Enables service routing
* Required for Kubernetes networking to work

---

## 🔹 Step 5: Install Container Runtime (containerd)

### Command

```bash
sudo apt update
sudo apt install -y containerd
```

### Explanation

* Kubernetes does not run containers directly
* `containerd` runs containers for Kubernetes

Generate default config:

```bash
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

Enable systemd cgroup:

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

Restart:

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## 🔹 Step 6: Install Kubernetes Components

### Command

```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg
```

### Explanation

* Required to securely download Kubernetes packages

Add Kubernetes repo & key:

```bash
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
| sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

```bash
sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /
EOF
```

Install tools:

```bash
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
```

Lock versions:

```bash
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 🔹 Step 7: Initialize Kubernetes Cluster (Master Only)

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

### Explanation

* Creates control plane components
* Generates certificates
* Starts API server
* `--pod-network-cidr` → required for Calico

⚠️ Save the **kubeadm join command**.

---

## 🔹 Step 8: Configure kubectl

```bash
sudo mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Explanation

* kubectl needs cluster credentials
* This connects kubectl to Kubernetes API

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

* Kubernetes does not support networking by default
* Calico provides:

  * Pod IPs
  * Pod-to-pod communication
  * Network policies

Check:

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
* Worker becomes ready for pods

---

## ✅ Final Validation

```bash
sudo kubectl get nodes
sudo kubectl get pods -A
```

All nodes should be **Ready**.

---

## 🛠 Troubleshooting (Very Important)

### Error

```
dial tcp 127.0.0.1:8080: connect: connection refused
```

### Reason

* kubectl is not using correct kubeconfig
* Proxy variables are set

### Fix

```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
```

Reconfigure kubeconfig and retry Calico.

---

## 🧹 Cleanup

```bash
sudo kubeadm reset -f
```

---

## 🎯 Conclusion

You have successfully:

* Installed Kubernetes using kubeadm
* Configured containerd
* Enabled Calico networking
* Built a real DevOps-ready lab

---

### 👨‍🏫 Author

**Rushikesh N (Rushi)**
DevOps & Cloud Trainer | AWS | Kubernetes

---

