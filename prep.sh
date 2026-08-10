#!/bin/bash
set -e

echo ">>> Tắt swap"
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

echo ">>> Nạp kernel module"
sudo modprobe overlay
sudo modprobe br_netfilter

echo ">>> Cấu hình sysctl"
cat <<EOT | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOT
sudo sysctl --system

echo ">>> Cài containerd"
sudo apt update
sudo apt install -y containerd

echo ">>> Cấu hình containerd dùng SystemdCgroup"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

echo ">>> DONE prep.sh"

echo ">>> Tạo thư mục keyrings"
sudo mkdir -p /etc/apt/keyrings
echo ">>> Cài kubelet, kubeadm, kubectl"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo ">>> DONE kubeadm install"
