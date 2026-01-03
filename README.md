# DevopsK8S - Flux CD & Terraform DIY

This project demonstrates a GitOps-based deployment of the `kbot` Telegram bot using Terraform and Flux CD. It supports both a local testing environment (Kind) and a production-ready environment (GKE).

## Project Structure

- `kind/`: Local development environment.
    - `bootstrap/`: Kind cluster and Flux CD installation.
    - `release/`: `kbot` application deployment and secrets.
- `gke/`: Production environment.
    - `bootstrap/`: GKE cluster and Flux CD installation.
    - `release/`: `kbot` application deployment and secrets.
- `templates/`: Shared Terraform templates (`.tftpl`) for Kubernetes manifests.

---

## 🚀 Lifecycle Guide (Kind & GKE)

The project is split to separate **Infrastructure** (Bootstrap) from **Application** (Release).

### 0. Required environment variables (use terraform.tfvars or TF_VAR_* variables)
kind/bootstrap/terraform.tfvars example:
```
github_owner    = "REDACTED"
github_token    = "REDACTED"
repository_name = "flux-config-kind"
```
kind/release/terraform.tfvars example:
```
github_owner    = "REDACTED"
github_token    = "REDACTED"
repository_name = "flux-config-kind"
TTOKEN          = "REDACTED"
``` 
gke/bootstrap/terraform.tfvars example:
```
GOOGLE_PROJECT  = "REDACTED"
GOOGLE_REGION   = "REDACTED"
GKE_NUM_NODES   = 1
github_owner    = "REDACTED"
github_token    = "REDACTED"
repository_name = "flux-config-gke"
```
gke/release/terraform.tfvars example:
```
GOOGLE_PROJECT  = "REDACTED"
GOOGLE_REGION   = "europe-west1"
github_owner    = "gray380"
github_token    = "REDACTED"
repository_name = "flux-config-gke"
TTOKEN          = "REDACTED"
``` 
### 1. Recreate / Deploy
Always deploy **Bootstrap** before **Release**.

```bash
# Example for Kind
cd tf-k8s-diy/kind/bootstrap
terraform init
terraform plan -varfile="terraform.tfvars" -out=.plan.out
terraform apply .plan.out

cd ../release
terraform init
terraform plan -varfile="terraform.tfvars" -out=.plan.out
terraform apply .plan.out
```

### 2. Doublecheck (Verification)
Check both the **Terraform State** and the **Cluster State**.

*   **Infrastructure (Bootstrap)**: 
    *   Verify Flux pods: `kubectl --kubeconfig=../kubeconfig get pods -n flux-system`
*   **Application (Release)**:
    *   Verify kbot pod: `kubectl --kubeconfig=../kubeconfig get pods -n flux-system -l app.kubernetes.io/name=kbot`
    *   Check Flux status: `flux --kubeconfig=../kubeconfig get all`
*   **Terraform Plan**: Run `terraform plan` in any directory to ensure no drift exist.

### 3. Destroy (Cleanup)
Always destroy **Release** before **Bootstrap**.

```bash
# 1. Remove Application first
cd tf-k8s-diy/kind/release
terraform destroy -var="TTOKEN=ANY_STRING" -auto-approve

# 2. Remove Infrastructure
cd ../bootstrap
terraform destroy -auto-approve
```

> [!IMPORTANT]
> **GKE Destruction**: GKE clusters often have `deletion_protection = true` by default. If the destroy fails, you must set this to `false` in the GKE module configuration.
> **GitHub Repos**: `terraform destroy` will attempt to delete the `flux-config-*` repositories. If your GitHub Token lacks "Admin" permissions, you must delete these repositories manually on GitHub.

---

## 🛠 Prerequisites

- [Terraform](https://www.terraform.io/downloads)
- [Docker](https://www.docker.com/products/docker-desktop) (for Kind)
- [gcloud SDK](https://cloud.google.com/sdk/docs/install) (for GKE)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Flux CLI](https://fluxcd.io/flux/installation/) (optional, for debugging)
- A GitHub Personal Access Token (PAT) with `repo` and `packages` (read) scopes.
- A Telegram Bot Token (from [@BotFather](https://t.me/botfather)).

> [!NOTE]
> **Kubeconfig Management**: You do not need to create `kubeconfig` files manually. Terraform will automatically generate a local `kubeconfig` file in the `kind/` or `gke/` directory during the first `terraform apply`.
