# Deployment Guide

This walks through deploying the whole platform from nothing to a running app on HTTPS. Follow it top to bottom.

## Before you start

You need these installed locally:

- AWS CLI (v2, recent build) configured with credentials for your account
- Terraform 1.10 or newer
- kubectl
- helm
- A domain with a hosted zone in Route53 (or a subdomain delegated to Route53)

Quick check:

```bash
aws sts get-caller-identity
terraform version
kubectl version --client
helm version
```

The deploy happens in two stages. First a one time bootstrap that creates the things Terraform itself needs to store state and authenticate CI. Then the main infrastructure and everything on top of it.

## Step 1: Bootstrap

The bootstrap creates the S3 bucket for Terraform state, the ECR repository for the app image, and the GitHub OIDC provider and role that lets the pipelines talk to AWS without long lived keys.

```bash
cd infra/bootstrap
terraform init
terraform apply
```

When it finishes, grab the two outputs. You need them for the GitHub setup in the next step.

```bash
terraform output github_oidc_role_arn
terraform output ecr_repository_url
```

Keep these two values handy.

## Step 2: GitHub secrets and variables

Go to your repo on GitHub, then Settings, then Secrets and variables, then Actions.

Add these under **Secrets**:

| Name | Value |
|------|-------|
| `OIDC_ARN` | the `github_oidc_role_arn` output from bootstrap |
| `GRAFANA_ADMIN_PASSWORD` | any password you choose for Grafana |

Add these under **Variables**:

| Name | Value |
|------|-------|
| `AWS_REGION` | `eu-central-1` |
| `ECR_REPOSITORY` | the repository name only, like `eks-gitops-platform/it-tools` (not the full URL) |
| `EKS_CLUSTER_NAME` | `eks-gitops-platform-lab-cluster` |

The `ECR_REPOSITORY` one trips people up. Use just the repo path, not the full registry URL. The pipeline builds the full image reference itself.

## Step 3: Deploy the infrastructure

This provisions the VPC, the EKS cluster and nodes, all the IAM and OIDC setup, and installs the cluster add-ons (NGINX Ingress, cert-manager, external-dns, ArgoCD, Prometheus and Grafana) through Helm.

You can run it through the Terraform pipeline (Actions tab, run the Terraform workflow, approve the apply when it asks) or locally:

```bash
cd infra
terraform init
terraform apply
```

This takes a while. The cluster alone is around seven minutes, the node group another five to ten, then the add-ons. Twenty to thirty minutes total is normal for EKS on a clean run.

## Step 4: Connect to the cluster

Point kubectl at the new cluster:

```bash
aws eks update-kubeconfig --name eks-gitops-platform-lab-cluster --region eu-central-1
```

The cluster uses API authentication mode, so your IAM identity needs an access entry to actually talk to it. This is already configured in `infra/modules/eks/access.tf` for my own admin user — see the note below if you're running this yourself. After that:

```bash
kubectl get nodes
kubectl get pods -A
```

You should see three nodes ready and pods running across the argocd, cert-manager, external-dns, ingress-nginx and monitoring namespaces.

> Note: `infra/modules/eks/access.tf` has my own IAM ARN hardcoded for local kubectl access. If you're running this yourself, swap it for your own ARN (find it with `aws sts get-caller-identity`).

## Step 5: Deploy the app

The ArgoCD application manifests tell ArgoCD what to deploy. Apply them once:

```bash
kubectl apply -f k8s/argocd/applications/
```

This is also what the app pipeline does on every run, so after this first apply it stays in sync automatically.

Now run the app pipeline (Actions tab, run the App workflow). It builds the IT Tools image, scans it, pushes it to ECR, updates the image tag in the deployment manifest, and ArgoCD picks up the change and rolls it out.

Check that ArgoCD is happy:

```bash
kubectl get applications -n argocd
```

Both `it-tools` and `cert-manager-config` should show Synced and Healthy. Give cert-manager a couple of minutes to get the TLS certificate from Let's Encrypt and external-dns a moment to create the DNS record. Then the app is live at `https://eks.lab.nashar.dev`.

## Accessing the ArgoCD dashboard

ArgoCD has no public URL by design. Reach it with a port-forward:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Leave that running and open `https://localhost:8080` in your browser. It uses a self signed cert so the browser will warn you, just continue past it.

Log in with username `admin`. Get the password with:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

The `; echo` at the end just adds a line break so you can see exactly where the password ends.

## Accessing Grafana

Same idea, port-forward to Grafana:

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Open `http://localhost:3000`. Log in with username `admin` and the password you set as `GRAFANA_ADMIN_PASSWORD` in the GitHub secrets.

Once you are in, the dashboards are under the Dashboards menu. The Kubernetes compute and Node Exporter ones show CPU, memory, pod health and node status. The Networking dashboard shows traffic per namespace.

## Troubleshooting

**Helm releases fail with "Kubernetes cluster unreachable: the server has asked for the client to provide credentials"**: the identity running Terraform doesn't have access to the cluster's Kubernetes API yet. Make sure `bootstrap_cluster_creator_admin_permissions = true` is set in the EKS cluster's `access_config`, and that the access entry for your admin identity exists (see Step 4). Note that changing `bootstrap_cluster_creator_admin_permissions` on an existing cluster forces a replacement, so it's best to get this right before the first apply.

## Teardown

Order matters here. The Kubernetes workloads create AWS resources like the load balancer and DNS records that Terraform does not track, so those need to go first, otherwise the VPC destroy will hang.

Delete the ArgoCD apps (this removes the app and the ClusterIssuer):

```bash
kubectl delete -f k8s/argocd/applications/
```

Uninstall the Helm add-ons. This is what tears down the load balancer:

```bash
helm uninstall ingress-controller -n ingress-nginx
helm uninstall cert-manager -n cert-manager
helm uninstall external-dns -n external-dns
helm uninstall argocd -n argocd
helm uninstall monitoring -n monitoring
```

external-dns leaves its DNS records behind because the pod is gone before it can clean them up. They are harmless and cost nothing, but if you want a tidy hosted zone you can delete the `eks.lab.nashar.dev` records manually in the Route53 console.

Give AWS a minute to fully remove the load balancer, then destroy the rest:

```bash
cd infra
terraform destroy
```

That removes the cluster, nodes, VPC and everything else. The bootstrap resources (state bucket, ECR, OIDC role) stay, since those are meant to outlive individual deploys. If you want those gone too, run `terraform destroy` inside `infra/bootstrap` as well.
