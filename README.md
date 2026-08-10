# ☸️ CI/CD GitOps Pipeline: Terraform + Kubernetes (kubeadm) HA + GitLab + Harbor + ArgoCD + Observability on AWS

[![Terraform](https://img.shields.io/badge/build-passing-brightgreen?style=flat-square&logo=terraform&logoColor=white)](#-verification-checklist)

[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Calico](https://img.shields.io/badge/Calico-4E4A4B?style=for-the-badge&logo=projectcalico&logoColor=white)](https://www.tigera.io/project-calico/)
[![GitLab](https://img.shields.io/badge/GitLab_CE-FC6D26?style=for-the-badge&logo=gitlab&logoColor=white)](https://about.gitlab.com/)
[![Harbor](https://img.shields.io/badge/Harbor-60B932?style=for-the-badge&logo=harbor&logoColor=white)](https://goharbor.io/)
[![ArgoCD](https://img.shields.io/badge/Argo_CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![Helm](https://img.shields.io/badge/Helm-0F1626?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh/)
[![Let's Encrypt](https://img.shields.io/badge/Let's_Encrypt-003A70?style=for-the-badge&logo=letsencrypt&logoColor=white)](https://letsencrypt.org/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![Loki](https://img.shields.io/badge/Loki-F5A800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/oss/loki/)
[![Velero](https://img.shields.io/badge/Velero-2F7DC3?style=for-the-badge&logo=veleroio&logoColor=white)](https://velero.io/)
[![Telegram](https://img.shields.io/badge/Telegram_Alerts-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://core.telegram.org/bots)

<details>
<summary><strong>📑 Table of Contents (Click to expand)</strong></summary>

- 📌 [Introduction](#introduction)
- 🚀 [Key Features](#key-features)
- 🏗️ [Architecture Overview](#architecture-overview)
- 📁 [Project Structure](#project-structure)
- 🛠️ [Technologies Used](#technologies-used)
- ☁️ [AWS Infrastructure Setup](#aws-infrastructure-setup)
- 💻 [Quick Start](#quick-start)
- ✅ [Verification Checklist (19 items)](#verification-checklist)
- 🔒 [HTTPS Everywhere](#https-everywhere)
- 💾 [Backup & Disaster Recovery](#backup-disaster-recovery)
- ⚠️ [Troubleshooting & Lessons Learned](#troubleshooting-lessons-learned)
- 🔮 [Production Gaps & Future Improvements](#future-production-improvements)
- 👤 [Author](#author)

</details>

---

<h2 id="introduction">📌 Introduction</h2>

This repository documents a complete, self-built **HA CI/CD GitOps pipeline** deployed on **8 AWS EC2 instances**, fully provisioned from scratch with **Terraform** — no managed Kubernetes service (EKS), no managed CI service, no managed registry.

The project demonstrates end-to-end DevOps practice at production-adjacent scale: **Infrastructure as Code** (VPC, Security Groups, NLB, EC2 — all via Terraform), a **highly-available Kubernetes control plane** (3 `kubeadm` master nodes across 3 Availability Zones behind a Network Load Balancer), **self-hosted CI/CD** (GitLab CE + GitLab Runner + Trivy vulnerability scanning), a **self-hosted container registry** (Harbor), **GitOps continuous delivery** (ArgoCD, Sealed Secrets, 3 isolated environments), **automated HTTPS** everywhere (cert-manager + Let's Encrypt for in-cluster services, Certbot for standalone EC2 services), **full-stack observability** (Prometheus, Grafana, Loki, Alertmanager → Telegram), and **disaster recovery** (Velero backup/restore to S3).

Every stage was built, broken, and debugged manually — see the [Troubleshooting section](#troubleshooting-lessons-learned) for a curated set of the real-world issues encountered and resolved along the way (the full internal incident log runs past 60 documented issues across networking, Terraform/HCL, Kubernetes CNI, GitOps, and observability).

---

<h2 id="key-features">🚀 Key Features</h2>

*   🏗️ **Infrastructure as Code, end to end**: 1 control VM + 3 HA master nodes (multi-AZ) + 2 worker nodes + GitLab VM + Harbor VM — VPC, subnets, Security Groups, Network Load Balancer, IAM, and all 8 EC2 instances declared in Terraform, state backed by S3 + DynamoDB locking.
*   ☸️ **Self-managed HA Kubernetes**: cluster bootstrapped with `kubeadm`, 3 control-plane nodes fronted by an internal NLB for the API server, Calico as CNI, `ingress-nginx` running as a `hostNetwork` DaemonSet to bind ports 80/443 directly on worker nodes.
*   🔁 **Fully Automated CI/CD Loop**: `git push` → GitLab CI (4-stage pipeline: build → Trivy scan → push to Harbor → update Helm chart) → ArgoCD detects the new image tag and auto-syncs — zero manual deployment steps.
*   🔐 **GitOps-native Secrets**: Sealed Secrets encrypts credentials before they ever touch Git, safely committed and decrypted only inside the target cluster — with per-namespace sealing across `dev`/`staging`/`prod`.
*   🌐 **Automated HTTPS Everywhere**: `cert-manager` + Let's Encrypt for ArgoCD (in-cluster `ClusterIssuer`), Certbot-managed TLS for GitLab CE and Harbor (standalone EC2 services) — all 3 admin UIs served over valid, browser-trusted certificates.
*   📊 **Full-stack Observability with Alerting**: `kube-prometheus-stack` (Prometheus + Grafana) for metrics, Loki + Promtail for centralized logs, and Alertmanager wired to a Telegram bot for real-time incident notifications.
*   💾 **Tested Disaster Recovery**: Velero backs up the cluster to S3 on a schedule, with a verified restore drill (delete → restore → confirm pods recover) as part of the acceptance checklist.

---
<h2 id="architecture-overview">🏗️ Architecture Overview</h2>

![Sơ đồ kiến trúc CI/CD GitOps trên AWS](2.png)

<h2 id="project-structure">📁 Project Structure</h2>

```text
gitops-lab-aws/
├── README.md
├── docs/
│   └── screenshots/                    # 19 verification screenshots (checklist below)
│
├── terraform/                          # Infrastructure as Code
│   ├── prep.sh                         # Bootstrap script for control-vm
│   ├── versions.tf                     # Provider + backend (S3 + DynamoDB lock)
│   ├── variables.tf                    # admin_cidr, vpc_cidr, region...
│   ├── network.tf                      # VPC, public subnets (3 AZ), IGW, route tables
│   ├── security_groups.tf              # SG "k8s" + SG "gitlab_harbor"
│   ├── iam.tf                          # IAM role/instance profile for nodes
│   ├── keypair.tf                      # EC2 key pair for Terraform-managed nodes
│   ├── instances.tf                    # 3 master + 2 worker + gitlab + harbor EC2
│   └── loadbalancer.tf                 # Internal NLB (target group + listener) for API server
│
├── helm-chart/                         # GitOps repo watched by ArgoCD
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   ├── values-prod.yaml
│   ├── templates/
│   └── sealed-secret-<env>.yaml        # Sealed per namespace (dev/staging/prod)
│
├── app-code/                           # Application source (CI-facing repo)
│   ├── .gitlab-ci.yml                  # 4-stage pipeline: build → scan → push → update-chart
│   ├── Dockerfile
│   └── src/
│
└── monitoring/
    ├── cluster-issuer.yaml             # cert-manager ClusterIssuer (Let's Encrypt)
    ├── prometheus-rule.yaml            # Custom PrometheusRule (PodCrashLooping)
    └── alertmanager-config.yaml        # Alertmanager → Telegram receiver override
```

> **Note:** in the live environment, `app-code/` and `helm-chart/` are separate GitLab repositories — the CI pipeline in `app-code` auto-commits the new image tag into `helm-chart`, which ArgoCD watches independently. They are shown together here for readability.

---

<h2 id="technologies-used">🛠️ Technologies Used</h2>

| Layer | Technology | Description |
|---|---|---|
| **Cloud Provider** | ![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat-square&logo=amazon-aws&logoColor=white) | 8x EC2 across 3 Availability Zones — control-vm, 3 master, 2 worker, GitLab, Harbor |
| **Infrastructure as Code** | ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white) | VPC, subnets, Security Groups, IAM, NLB, and all 8 EC2 instances; state on S3 + DynamoDB lock |
| **Orchestration** | ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white) | Self-managed HA cluster via `kubeadm`, 3-node control plane behind an internal NLB |
| **CNI** | ![Calico](https://img.shields.io/badge/Calico-4E4A4B?style=flat-square&logo=projectcalico&logoColor=white) | Pod networking + BGP, with `source_dest_check=false` on EC2 ENIs for correct routing |
| **Ingress** | ![NGINX](https://img.shields.io/badge/ingress--nginx-009639?style=flat-square&logo=nginx&logoColor=white) | `hostNetwork` + `DaemonSet` — binds ports 80/443 directly on worker nodes |
| **CI Server** | ![GitLab](https://img.shields.io/badge/GitLab_CE-FC6D26?style=flat-square&logo=gitlab&logoColor=white) | Self-hosted GitLab CE + Runner, 4-stage pipeline with Trivy vulnerability scanning |
| **Container Registry** | ![Harbor](https://img.shields.io/badge/Harbor-60B932?style=flat-square&logo=harbor&logoColor=white) | Self-hosted Harbor, per-project access control |
| **GitOps / CD** | ![ArgoCD](https://img.shields.io/badge/Argo_CD-EF7B4D?style=flat-square&logo=argo&logoColor=white) | Auto-Sync + Self-Heal across 3 isolated environments (dev/staging/prod) |
| **Secrets Management** | ![SealedSecrets](https://img.shields.io/badge/Sealed_Secrets-1A73E8?style=flat-square&logo=kubernetes&logoColor=white) | `kubeseal` — secrets encrypted before hitting Git, sealed per namespace |
| **Package Management** | ![Helm](https://img.shields.io/badge/Helm-0F1626?style=flat-square&logo=helm&logoColor=white) | Helm charts for `kube-prometheus-stack`, `loki-stack`, Calico, ingress-nginx |
| **SSL/TLS** | ![Let's Encrypt](https://img.shields.io/badge/Let's_Encrypt-003A70?style=flat-square&logo=letsencrypt&logoColor=white) | `cert-manager` (in-cluster, ArgoCD) + Certbot (standalone EC2, GitLab/Harbor) |
| **Monitoring** | ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white) | `kube-prometheus-stack` — cluster + node + app metrics |
| **Visualization** | ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat-square&logo=grafana&logoColor=white) | Cluster resource dashboards + custom Loki log dashboard |
| **Log Aggregation** | ![Loki](https://img.shields.io/badge/Loki-F5A800?style=flat-square&logo=grafana&logoColor=white) | Loki + Promtail, queried via LogQL in Grafana Explore |
| **Alerting** | ![Telegram](https://img.shields.io/badge/Telegram-26A5E4?style=flat-square&logo=telegram&logoColor=white) | Alertmanager → Telegram Bot for real-time notifications |
| **Backup / DR** | ![Velero](https://img.shields.io/badge/Velero-2F7DC3?style=flat-square&logo=veleroio&logoColor=white) | Scheduled backups to S3, filesystem-based (no VolumeSnapshotClass needed), tested restore drill |

---

<h2 id="aws-infrastructure-setup">☁️ AWS Infrastructure Setup</h2>

### 1. Bootstrap the control-vm (once, via AWS Console)
A dedicated `control-vm` (`t3.micro`) runs all subsequent Terraform/kubectl/helm commands — created manually once via the Console with a dedicated Security Group and an `AdministratorAccess` IAM Role, since Terraform can't create the role it needs to run itself.

> ⚠️ **Must be created in the same VPC that Terraform provisions in step 2** — a control-vm left in the default VPC cannot route to the Kubernetes NLB/nodes, and every Security Group rule referencing it will silently fail.

### 2. Provision the 8-EC2 infrastructure with Terraform
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```
Creates: 1 VPC (3 public subnets across 3 AZs), 2 Security Groups (`k8s`, `gitlab_harbor`), 1 internal Network Load Balancer for the API server, and all 8 EC2 instances.

### 3. Bootstrap the Kubernetes cluster
```bash
# On each master (kubeadm init on master-1, kubeadm join --control-plane on master-2/3):
sudo kubeadm init --control-plane-endpoint "<nlb-dns>:6443" --upload-certs --pod-network-cidr=192.168.0.0/16

# Install Calico CNI:
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml

# Join workers:
sudo kubeadm join <nlb-dns>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

<h2 id="quick-start">💻 Quick Start</h2>

### Prerequisites
* AWS account with sufficient EC2/VPC/IAM quota
* A registered domain with DNS access
* `terraform`, `kubectl`, `helm`, `kubeseal` installed on the control-vm

### Deploy the full stack
```bash
# 1. Infrastructure
cd terraform && terraform apply

# 2. Kubernetes + CNI + Ingress (see AWS Infrastructure Setup above)

# 3. cert-manager + ClusterIssuer
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set installCRDs=true
kubectl apply -f monitoring/cluster-issuer.yaml

# 4. GitLab CE + Harbor (on their dedicated EC2 instances)
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo EXTERNAL_URL="https://gitlab.yourdomain.com" apt install -y gitlab-ce

# 5. ArgoCD + Sealed Secrets
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system

# 6. Observability
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
helm install loki grafana/loki-stack -n monitoring --set loki.image.tag=2.9.3

# 7. Push code — the pipeline takes it from here
git push
```

---

<h2 id="verification-checklist">✅ Verification Checklist (19 items)</h2>

Every item below was captured as a screenshot as proof of a working system:

| # | Item | Verified via |
|---|---|---|
| 1 | 8-EC2 infrastructure, HA across 3 AZ | AWS Console → EC2 → Instances |
| 2 | Kubernetes cluster `Ready` | `kubectl get nodes -o wide` |
| 3 | NLB healthy — all 3 masters | AWS Console → Target Groups |
| 4 | CI pipeline — 4 stages Passed | GitLab UI → CI/CD → Pipelines |
| 5 | Trivy vulnerability scan | Pipeline job log |
| 6 | Image pushed to Harbor | Harbor UI → Repositories |
| 7 | ArgoCD Apps Synced + Healthy | ArgoCD UI / `kubectl get applications -n argocd` |
| 8 | 3 environments actually running | `kubectl get pods -n myapp-{dev,staging,prod}` |
| 9 | Secrets encrypted in Git | GitLab UI → `sealed-secret.yaml` |
| 10 | Grafana cluster dashboard | Grafana UI |
| 11 | Alert delivered to Telegram | Telegram screenshot |
| 12 | Velero backup `Completed` | `velero backup get` |
| 13-14 | Restore drill (before/after) | `kubectl delete` → `velero restore create` → `kubectl get pods` |
| 15-17 | Valid HTTPS — GitLab / Harbor / ArgoCD | Browser padlock |
| 18 | `Certificate` Ready (cert-manager) | `kubectl get certificate -A` |
| 19 | Ingress pods on correct worker nodes | `kubectl get pods -n ingress-nginx -o wide` |

---

<h2 id="https-everywhere">🔒 HTTPS Everywhere</h2>

Three different TLS provisioning paths, matched to where each service actually runs:

* **ArgoCD** (in-cluster) → `cert-manager` + a `ClusterIssuer` watching an `Ingress` resource, HTTP-01 challenge.
* **GitLab CE / Harbor** (standalone EC2, outside the cluster) → Certbot/Nginx issuing Let's Encrypt certs directly on the host — outside the scope of `kubectl get certificate`, but verified independently via the browser padlock.

> A DaemonSet running with `hostNetwork: true` (like `ingress-nginx`) does **not** get scheduled onto control-plane nodes by default (`NoSchedule` taint) — any DNS record pointing at an in-cluster Ingress must resolve to a **worker** node's IP, confirmed via `kubectl get pods -n ingress-nginx -o wide` before touching DNS.

---

<h2 id="backup-disaster-recovery">💾 Backup & Disaster Recovery</h2>

Velero backs up the cluster to S3 using filesystem-level backup (`--default-volumes-to-fs-backup`), since a self-managed `kubeadm` cluster has no `VolumeSnapshotClass` out of the box:

```bash
velero backup create myapp-backup --include-namespaces myapp-dev,myapp-staging,myapp-prod
velero backup get

# Restore drill:
kubectl delete deployment myapp-dev -n myapp-dev
velero restore create --from-backup myapp-backup --include-namespaces myapp-dev
velero restore get
kubectl get pods -n myapp-dev
```

> ⚠️ Disable ArgoCD's `selfHeal` before restoring — otherwise ArgoCD reconciles the "missing" deployment back from Git before Velero finishes restoring it, masking whether the restore actually worked.

---

<h2 id="troubleshooting-lessons-learned">⚠️ Troubleshooting & Lessons Learned</h2>

Building this stack manually — Terraform, HA `kubeadm`, and a full GitOps/observability toolchain, with no managed services anywhere — surfaced a long list of real-world issues. Below are the most significant ones:

| # | Problem | Root Cause | Fix |
|---|---|---|---|
| 1 | `control-vm` could reach nothing — SSH hung, `kubectl` timed out via the NLB | `control-vm` was created in the AWS *default* VPC before Terraform's VPC existed — two separate, unrouted VPCs | Recreate `control-vm` inside the Terraform-managed VPC + public subnet, after backing up local Terraform code |
| 2 | 2 `calico-node` pods stuck `READY 0/1`, log: `BIRD is not ready` | Security Group `k8s` had no rule for port `5473` (Typha) — Calico couldn't sync config to render BGP | Add `ingress { from_port=5473 to_port=5473 protocol="tcp" self=true }` to the SG, `terraform apply`, delete the stuck pod |
| 3 | `curl` to port 80 gave `Connection refused` despite an `iptables REDIRECT` to the NodePort | `REDIRECT` is a *terminating target* — it short-circuits the packet before `kube-proxy`'s `KUBE-SERVICES` chain can NAT it to the right pod | Drop `iptables REDIRECT`; reinstall `ingress-nginx` with `hostNetwork=true` + `kind=DaemonSet` so it binds ports 80/443 directly |
| 4 | Grafana wouldn't load; Loki datasource failed with `parse error: unexpected IDENTIFIER` | SG missing a rule for port 3000; separately, `loki-stack`'s default image tag (`2.6.1`) was too old for Grafana 13.x's newer health-check query | Open port 3000 for the client IP; `helm upgrade loki -n monitoring grafana/loki-stack --reuse-values --set loki.image.tag=2.9.3` |
| 5 | Alertmanager → Telegram config `helm upgrade` failed: `undefined receiver "null" used in route` | `kube-prometheus-stack` ships a hidden default route for the `Watchdog` alert pointing at a `null` receiver; overriding `receivers:` without keeping `null` breaks the Operator's reconcile | Declare an explicit empty `null` receiver alongside `telegram` in the override values |
| 6 | Sealed Secrets: `helm repo add` 404'd, then `kubeseal` failed with `services "sealed-secrets-controller" not found` | Upstream repo `bitnami-labs.github.io` had merged into `bitnami.github.io`; separately, the Helm release name (`sealed-secrets`) creates a Service named `sealed-secrets`, not the CLI's hardcoded default `sealed-secrets-controller` | Use `https://bitnami.github.io/sealed-secrets`; pass `--controller-name=sealed-secrets --controller-namespace=kube-system` explicitly to `kubeseal` |
| 7 | `argocd-applicationset-controller` stuck `CrashLoopBackOff` after applying its CRD | `kubectl apply` (client-side) hit the 256KB hard limit on the `last-applied-configuration` annotation — the `ApplicationSet` CRD schema is too large | `kubectl apply --server-side --force-conflicts -f applicationset-crd.yaml` |
| 8 | A single `SealedSecret` worked in `dev` but failed to decrypt in `staging`/`prod`: `no key could decrypt secret` | `kubeseal`'s default scope binds the ciphertext to one exact `(namespace, name)` pair — it isn't portable across namespaces | Seal the same plaintext secret once **per namespace** (`dev`, `staging`, `prod`), and add `ignoreDifferences` in the ArgoCD `Application` to avoid false `OutOfSync` on the `status` field |
| 9 | GitLab CE hung for tens of minutes during `gitlab-ctl reconfigure` | Not CPU or disk — genuinely out of RAM on a `t3.medium` (4GB); CPU usage looked deceptively low (~49%) the whole time | Move `gitlab-vm` to an 8GB-RAM instance type |
| 10 | ArgoCD domain (`argocd.yourdomain.com`) got `connection refused` on the Let's Encrypt HTTP-01 challenge, even with correct DNS | The DNS record pointed at a **master** node, but `ingress-nginx` (DaemonSet, `hostNetwork`) never schedules onto control-plane nodes (`NoSchedule` taint) — nothing was listening there | Point the DNS record at a **worker** node's IP, confirmed via `kubectl get pods -n ingress-nginx -o wide` |

*(The full internal incident log covers 60+ issues across Terraform/HCL syntax, NLB hairpinning, etcd quorum on EC2 stop/start, DNS TTL caching, and more.)*

---

<h2 id="future-production-improvements">🔮 Production Gaps & Future Improvements</h2>

This project was built for hands-on learning and portfolio demonstration. In a real-world production system, the following would additionally be required:

- **IAM least-privilege**: replace the `AdministratorAccess` role on `control-vm` with a scoped policy for exactly the actions Terraform needs.
- **etcd/control-plane resilience**: automated, staggered start-up procedure for the 3 master nodes to avoid losing `etcd` quorum after a stop/start cycle.
- **Network Policies & RBAC**: namespace isolation and least-privilege Kubernetes RBAC across all deployed components.
- **Automated testing**: unit/integration tests as a required pipeline stage before the Docker build.
- **Multi-region DR**: cross-region S3 replication for Velero backups and Terraform state.
- **Config drift detection**: scheduled `terraform plan` in CI to catch manual console changes before they compound.
- **Secrets rotation**: automated rotation policy for Sealed Secrets and the Harbor/GitLab service accounts.

---

<h2 id="author">👤 Author</h2>

**Doan Minh Hiep**

*   **GitHub**: [@minhhiep05](https://github.com/minhhiep05)
*   **Email**: [doanhiep169@gmail.com](mailto:doanhiep169@gmail.com)
