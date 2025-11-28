# Interview Backend - Implementation Guide

> **Note:** This document provides implementation details and usage instructions. For the original assignment requirements, see [sre/README.md](sre/README.md).

## 📁 Repository Structure

```
interview/
├── backend/                    # Spring Boot application
│   ├── Dockerfile              # Multi-stage Docker build
│   ├── entrypoint.sh           # Container entrypoint with JVM tuning
│   ├── .dockerignore           # Docker build exclusions
│   ├── pom.xml                 # Maven dependencies
│   └── src/                    # Application source code
├── sre/
│   └── helm/                   # Production-ready Helm chart
│       ├── Chart.yaml          # Chart metadata
│       ├── values-prod.yaml    # Production values
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── serviceaccount.yaml
│           ├── ingress.yaml              # Dual ALB (public/private)
│           ├── hpa.yaml                  # Horizontal Pod Autoscaler
│           ├── pdb.yaml                  # Pod Disruption Budget
│           ├── configmap.yaml            # Optional JVM config
│           ├── servicemonitor.yaml       # Prometheus metrics
│           ├── instrumentation.yaml      # OpenTelemetry auto-instrumentation
│           ├── probes.yaml               # Blackbox Exporter SLA monitoring
│           ├── iam.yaml                  # AWS IRSA (IAM Roles for Service Accounts)
│           ├── secret-provider.yaml      # AWS Secrets Manager CSI driver
│           ├── networkpolicy.yaml        # Network security policies
│           └── _helpers.tpl              # Reusable Helm templates
├── .github/
│   └── workflows/
│       └── backend-cicd.yml    # CI/CD pipeline
├── Makefile                    # Development and testing commands
├── README.md                   # Original assignment
└── INTERVIEW.md                # This file
```

## 📋 Prerequisites

### Infrastructure Prerequisites (I Already Deployed)

For this implementation, I'm using my existing personal sandbox AWS production environment with the following infrastructure already in place:

#### Infrastructure Layout

The following infrastructure is deployed via Terraform/Terragrunt and managed in a separate repository(not in PR):

```
terraform-infrastructure/
├── prod/
│   └── us-east-2/                    # Primary production region
│       ├── aws-vpc/                  # Multi-AZ VPC with public/private subnets
│       ├── aws-route53/              # Split-view dns public/private hosted zones
│       ├── aws-acm/                  # TLS certificates
│       ├── aws-ecr/                  # Container registry
│       ├── aws-iam/                  # IAM roles and policies
│       ├── aws-tf-state/             # Remote state with S3 + state locking
│       ├── argocd/                   # ArgoCD ApplicationSets
│       │   └── developers.yaml       # ← Interview app ApplicationSet
│       ├── github/                   # GitHub repo management, secrets, OIDC provider etc
│       ├── openvpn/                  # VPN access server to access private resources
│       └── prod-eks/                 # EKS cluster with add-ons
│           ├── Cluster (v1.33)
│           ├── Node Groups (managed)
│           ├── ArgoCD               # GitOps controller
│           ├── AWS Load Balancer Controller
│           ├── External DNS
│           ├── Cert Manager
│           ├── Stakater Reloader 
│           ├── ACK IAM Controller
│           ├── Cluster Autoscaler
│           ├── Karpenter
│           └── Observability Stack:
│               ├── Prometheus (kube-prometheus-stack)
│               ├── Grafana
│               ├── Loki             # Logs
│               ├── Tempo            # Traces
│               ├── Mimir            # Metrics
│               ├── OpenTelemetry Collector
│               ├── OpenTelemetry Operator
│               └── Blackbox Exporter
└── terraform-modules/                # Reusable Terraform modules
    ├── aws-vpc/
    ├── aws-eks/
    ├── aws-ecr/
    ├── aws-iam/
    ├── aws-acm/
    └── ... (10+ modules)
```

> **Note:** The infrastructure setup (VPC, EKS, observability stack) is managed via Terraform in a separate 'terraform-infrastructure' repository with 10+ reusable modules in another separate 'terraform-modules' repo. This is not included in this PR to keep it focused on **application deployment** only as per take-home requirements. Happy to share though (^_^)

## 🏗️ Architecture Overview

![GitOps CI/CD Architecture](sre/interview.jpg)

### Deployment Flow

1. **Developer** pushes code to GitHub
2. **GitHub Actions** (CI Server):
   - Builds Maven package
   - Creates Docker image
   - Pushes to Amazon ECR
   - Updates image tag in GitOps repo
   - PR is created pending prod approval
3. **ArgoCD** watches GitOps repo for changes
4. **ArgoCD** syncs manifests to EKS cluster
5. **Kubernetes** deploys new pods with updated image
6. **Application** reports health status back to ArgoCD

---

## 🚀 Quick Start

### Deploying to Your Existing Infrastructure

If you have an existing AWS EKS environment with the prerequisites listed above, deployment is straightforward:

1. **Update Helm Values** (`sre/helm/values-prod.yaml`):
   ```yaml
   aws:
     accountId: "YOUR_AWS_ACCOUNT_ID"
     region: "YOUR_AWS_REGION"
     eksName: "YOUR_EKS_CLUSTER_NAME"
     albCertificateArn: "YOUR_ACM_CERT_ARN"
     oidcProvider: "YOUR_OIDC_PROVIDER"
   
   image:
     repository: "YOUR_ECR_REPO"
     tag: "latest"
   ```

2. **Push to GitHub** - CI/CD pipeline automatically:
   - Builds Docker image
   - Pushes to your ECR
   - Updates GitOps repo with new image tag

3. **ArgoCD Syncs** - Automatically deploys to EKS

That's it! The application is now running with full observability.

---

### Local Development Prerequisites
- Docker
- Helm 3.x
- kubectl (configured with EKS cluster access)
- Make (optional, but recommended)

### Using the Makefile for local testing

The Makefile is located in the `sre/` directory for since this is a mono-repo with multiple projects.

```bash
# Navigate to sre directory
cd sre

# Show all available commands
make help

# Quick development workflow
make docker-build         # Build Docker image
make docker-run           # Start container
make docker-test          # Test /api/welcome endpoint
make docker-logs          # View logs
make docker-stop          # Stop container

# Validation workflows
make helm-lint            # Lint Helm chart
make helm-template        # Render Helm templates
make helm-dry-run         # Test Helm deployment (requires kubectl context)
make helm-validate        # Full Helm validation

# Combined workflows
make build-and-test       # Build, run, test, cleanup
make local-deploy         # Build + Helm dry-run
```
---

