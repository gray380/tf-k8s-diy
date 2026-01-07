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
    *   Verify kbot pod: `kubectl --kubeconfig=../kubeconfig get pods -n demo -l app.kubernetes.io/name=kbot`
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

---

## 🔐 Advanced Secret Management (SOPS + KMS) - GKE Only

The GKE environment uses a **Senior-level** SOPS-KMS workflow for secure secret management. Secrets are stored in GCP Secret Manager, encrypted with SOPS using Cloud KMS, and automatically deployed via GitHub Actions.

### Architecture Overview

```
GCP Secret Manager → GitHub Actions → SOPS Encryption → flux-config-gke repo → Flux → Kubernetes Secret
     (TTOKEN)           (WIF Auth)      (KMS Key)         (encrypted)        (decrypts)    (demo namespace)
```

### Prerequisites for SOPS-KMS

1. **Create Secret in GCP Secret Manager**

```bash
# Set your project
export GOOGLE_PROJECT="your-project-id"
gcloud config set project $GOOGLE_PROJECT

# Create the TELE_TOKEN secret
echo -n "YOUR_TELEGRAM_BOT_TOKEN" | gcloud secrets create TELE_TOKEN \
  --data-file=- \
  --replication-policy="automatic"

# Verify creation
gcloud secrets describe TELE_TOKEN
gcloud secrets versions access latest --secret="TELE_TOKEN"
```

2. **Apply Bootstrap Infrastructure**

```bash
cd gke/bootstrap
terraform init
terraform apply -var-file=terraform.tfvars
```

**Save these outputs:**
- `workload_identity_provider` - For GitHub Actions authentication
- `gha_service_account` - For GitHub Actions authentication

3. **Configure GitHub Repository**

Add these **Secrets** at `https://github.com/YOUR_USERNAME/tf-k8s-diy/settings/secrets/actions`:

| Secret Name | Value | Source |
|-------------|-------|--------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/123.../providers/github-provider` | Terraform output |
| `GCP_SERVICE_ACCOUNT` | `gha-sa@PROJECT.iam.gserviceaccount.com` | Terraform output |
| `GH_PAT` | Your GitHub Personal Access Token | [Create here](https://github.com/settings/tokens) |

Add this **Variable**:

| Variable Name | Value |
|---------------|-------|
| `GOOGLE_PROJECT` | Your GCP Project ID |

4. **Trigger Secret Encryption Workflow**

The workflow `.github/workflows/encrypt-secrets.yaml` will:
- Fetch `TELE_TOKEN` from Secret Manager
- Encrypt it with SOPS using Cloud KMS
- Commit encrypted secret to `flux-config-gke` repository

Trigger manually:
```bash
gh workflow run encrypt-secrets.yaml --ref main
# Or via GitHub UI: Actions → Encrypt Secrets → Run workflow
```

5. **Apply Release Configuration**

```bash
cd ../release
terraform init
terraform apply -var-file=terraform.tfvars
```

Flux will automatically decrypt and apply the secret to the `demo` namespace.

### Verification

```bash
# Get GKE credentials
gcloud container clusters get-credentials <cluster-name> --region=<region>

# Check Flux reconciliation
flux get kustomizations -n flux-system

# Verify secret exists and is decrypted
kubectl get secret kbot -n demo
kubectl get secret kbot -n demo -o jsonpath='{.data.token}' | base64 -d

# Check kbot pod
kubectl get pods -n demo
kubectl logs -n demo -l app.kubernetes.io/name=kbot
```

### Secret Rotation

To update the Telegram token:

```bash
# Update secret in Secret Manager
echo -n "NEW_TELEGRAM_TOKEN" | gcloud secrets versions add TELE_TOKEN --data-file=-

# Trigger the encryption workflow again
gh workflow run encrypt-secrets.yaml --ref main

# Flux will automatically pick up the change and update the pod
```

### Cleanup

```bash
# 1. Destroy GKE resources
cd gke/release
terraform destroy -var-file=terraform.tfvars -auto-approve

cd ../bootstrap
# Note: You may need to remove 'prevent_destroy = true' from kms key in main.tf
terraform destroy -var-file=terraform.tfvars -auto-approve

# 2. Delete the secret from Secret Manager (Optional)
gcloud secrets delete TELE_TOKEN
```

---

## 🔄 GKE Full Redeployment (Clean Start)

If you have destroyed the environment and want to start over, follow this procedure to avoid "already exists" conflicts and Flux deadlocks.

### 1. Clear the Configuration Repository
Flux bootstrap fails if it finds existing manifests. Purge the `clusters/` folder in your `flux-config-gke` repo:
```bash
# You can use the purge_repo.py script in gke/bootstrap/
python3 gke/bootstrap/purge_repo.py clusters/
```

### 2. Restore the KMS Key
GCP schedules KMS keys for destruction for 24 hours. You must restore and enable it before Terraform can manage it again:
```bash
gcloud kms keys versions restore 1 --location=global --keyring=sops-key-ring --key=sops-key --project=YOUR_PROJECT_ID
gcloud kms keys versions enable 1 --location=global --keyring=sops-key-ring --key=sops-key --project=YOUR_PROJECT_ID
```

### 3. Handle Workload Identity Tombstones
GCP "soft-deletes" Identity Pools for 30 days. To redeploy immediately, you **must increment the version** in `gke/bootstrap/main.tf`:
```hcl
# main.tf
workload_identity_pool_id          = "github-pool-v4"      # Increment this (v3, v4, v5...)
workload_identity_pool_provider_id = "github-provider-v4"  # Increment this
```

### 4. Deploy Infrastructure
```bash
cd gke/bootstrap
terraform apply -var-file=terraform.tfvars -auto-approve
```
*If it fails with "KeyRing already exists", simply import it:*
```bash
terraform import google_kms_key_ring.key_ring projects/YOUR_PROJECT_ID/locations/global/keyRings/sops-key-ring
terraform apply -var-file=terraform.tfvars -auto-approve
```

### 5. Update & Sync
1. Update **`GCP_WORKLOAD_IDENTITY_PROVIDER`** in GitHub Actions secrets with the new `v4` ID from the Terraform output.
2. Manually trigger the **"Encrypt Secrets"** workflow in the Actions tab.
3. Flux will now pick up the secret, decrypt it, and start the `kbot` pod.

---

> [!WARNING]
> **Cost**: GCP Secret Manager is free for up to 6 secret versions and 10,000 accesses/month. Cloud KMS costs ~$0.06/month.

> [!IMPORTANT]
> **Kind Environment**: The local Kind environment does NOT use SOPS-KMS. It continues to use plain Kubernetes secrets managed directly by Terraform for simplicity.

