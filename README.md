# EKS GitOps Platform

A production grade Kubernetes platform on AWS EKS. The goal here wasn't just to get an app running in a cluster. It was to build the full platform around it, the way you'd actually set things up at a real company. Infrastructure as code, automatic certificates and DNS, GitOps deployments, monitoring, and proper CI/CD with security scanning.

The app running on top is [IT Tools](https://github.com/CorentinTh/it-tools), a lightweight collection of developer utilities built with Vue.js. The app is intentionally simple. It's not the focus. It just gives me something real to route traffic to, secure with HTTPS, and ship through the pipeline. The platform underneath is the actual project.

During the build it was served over HTTPS at `https://eks.lab.nashar.dev`. The infrastructure gets torn down between sessions to keep costs down, so see the screenshots below for the running setup.

## Architecture

![Architecture Diagram](docs/architecture.png)

Traffic comes in through a single Network Load Balancer that AWS provisions automatically when the NGINX Ingress Controller gets deployed. From there NGINX takes over the HTTP routing inside the cluster and forwards requests to the right service. The worker nodes sit in private subnets across three availability zones. Only the load balancer lives in the public subnets, so nothing in the cluster is directly exposed to the internet.

DNS and certificates are handled without any manual steps. When an Ingress gets created, external-dns picks it up and creates the matching record in Route53, and cert-manager requests a certificate from Let's Encrypt and proves domain ownership through a DNS challenge in Route53. Both of them talk to AWS using IRSA, so each pod only gets the permissions it actually needs instead of handing broad access to the whole node.

## Key Decisions

A few choices here were deliberate, and they're worth explaining because they shaped how the whole thing fits together.

**Custom Terraform modules instead of community ones.** I wrote the VPC and EKS modules from scratch rather than pulling in the popular community modules. Those modules are great, but they hide a lot. Writing my own meant I actually had to understand how the cluster, the OIDC provider, the node groups and the networking all connect. If something breaks, I know exactly where to look.

**NLB instead of ALB.** Since NGINX Ingress already handles all the HTTP routing inside the cluster, putting an ALB in front would just duplicate work that NGINX is already doing. A Network Load Balancer sits at layer 4 and passes traffic straight through to NGINX, which keeps things simpler and cheaper. One load balancer for everything instead of one per service.

**IRSA for pod permissions.** Rather than giving the worker nodes broad IAM permissions that every pod would inherit, each workload that needs AWS access gets its own role through IAM Roles for Service Accounts. cert-manager can touch Route53. external-dns can touch Route53. Nothing else can. This keeps the blast radius small and makes the trust boundaries obvious.

**S3 backend with native locking.** Terraform state lives in S3. I used the native `use_lockfile` locking that came in Terraform 1.10 instead of the older DynamoDB approach, so there's one less moving piece to manage.

**GitHub OIDC for CI/CD.** The pipelines authenticate to AWS through OIDC, so there are no long lived access keys sitting in GitHub secrets. GitHub hands each pipeline run a short lived token, AWS verifies it, and the trust policy is locked down to this specific repo.

**ArgoCD for deployments.** The CI/CD pipeline never runs `kubectl apply` directly. It builds the image, scans it, pushes it to ECR, and updates the image tag in Git. ArgoCD watches the repo and reconciles the cluster to match. Git is the single source of truth, and if anyone changes something manually in the cluster, ArgoCD pulls it back in line.

## Repository Structure

```
eks-gitops-platform/
│
├── .github/
│   └── workflows/
│       ├── terraform.yml     # Infra pipeline: Checkov, plan, manual approval, apply
│       └── app.yml           # App pipeline: build, Trivy scan, ECR push, update tag
│
├── app/
│   ├── Dockerfile            # Multi-stage build (node builder + nginx runtime)
│   ├── .dockerignore
│   └── it-tools/             # The IT Tools application source
│
├── infra/
│   ├── bootstrap/            # One-time setup: S3 state backend, ECR, GitHub OIDC
│   │   ├── main.tf
│   │   └── locals.tf
│   │
│   ├── main.tf               # Module calls
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── providers.tf          # AWS and Helm providers
│   │
│   └── modules/
│       ├── vpc/              # Custom VPC: subnets, IGW, NAT, route tables
│       └── eks/              # Custom EKS: cluster, node group, IAM, OIDC, IRSA, Helm
│
├── k8s/
│   ├── addons/               # Helm values for cluster add-ons
│   │   ├── nginx-ingress/
│   │   ├── cert-manager/     # values + ClusterIssuer
│   │   ├── external-dns/
│   │   ├── argocd/
│   │   └── monitoring/
│   │
│   ├── apps/
│   │   └── it-tools/         # Deployment, service, ingress manifests
│   │
│   └── argocd/
│       └── applications/     # ArgoCD Application manifests
│
└── README.md
```

## CI/CD

There are two pipelines and they do different jobs.

The **Terraform pipeline** handles the infrastructure. It runs Checkov to catch security misconfigurations in the Terraform code, checks formatting, validates, and runs a plan. The apply step sits behind a manual approval gate, so nothing changes in AWS until I sign off on the plan. The two jobs are split so apply only runs if plan succeeds first.

The **app pipeline** handles IT Tools. It builds the Docker image, scans it with Trivy for vulnerabilities, pushes it to ECR tagged with the Git commit SHA, and then updates the image tag in the deployment manifest and commits that back to the repo. That last commit is what triggers ArgoCD to roll out the new version. The pipeline itself never deploys anything. It just builds, scans, pushes, and points ArgoCD at the new image.

Both pipelines authenticate to AWS through GitHub OIDC, so there are no static credentials anywhere in the repo.

## Stack

| Area | Tools |
|------|-------|
| Infrastructure | Terraform (custom VPC and EKS modules) |
| Kubernetes | Amazon EKS |
| Ingress | NGINX Ingress Controller (NLB) |
| TLS | cert-manager + Let's Encrypt |
| DNS | external-dns + Route53 |
| GitOps | ArgoCD |
| CI/CD | GitHub Actions |
| Security scanning | Checkov (Terraform), Trivy (images) |
| Monitoring | Prometheus + Grafana (kube-prometheus-stack) |
| Container registry | Amazon ECR |
| App | IT Tools (Vue.js) |

## Deployment

The setup runs in two stages: a one time bootstrap that creates the resources Terraform itself needs (S3 state backend, ECR, GitHub OIDC), then the main infrastructure and add-ons. ArgoCD takes over deployments from there.

Full step by step deployment and teardown guide coming soon.
