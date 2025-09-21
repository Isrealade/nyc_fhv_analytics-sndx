# NYC FHV Analytics Dashboard - DevOps Internship Project

**NYC FHV Analytics Dashboard** is a comprehensive full-stack analytics platform for NYC For-Hire Vehicle (FHV) driver data, built with modern DevOps practices. This project demonstrates a complete CI/CD pipeline, infrastructure as code, GitOps deployment, and cloud-native architecture using AWS EKS, ArgoCD, and Terraform.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Ingress        │    │   Backend       │
│   React + Nginx │───▶│   ALB + TLS      │───▶│   Node.js API   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                                               ┌─────────────────┐
                                               │   RDS Postgres  │
                                               │   (AWS Managed) │
                                               └─────────────────┘
```

**Key Components:**
- **Frontend**: React 18 + Vite + Tailwind CSS + Chart.js
- **Backend**: Node.js + Express + PostgreSQL
- **Infrastructure**: AWS EKS + RDS + VPC + ALB + ECR
- **CI/CD**: GitHub Actions + Docker + Trivy + SonarQube
- **GitOps**: ArgoCD + ArgoCD Image Updater
- **Monitoring**: Prometheus + Grafana + AlertManager
- **IaC**: Terraform + Helm

## 📁 Project Structure

```
nyc_fhv_analytics-sndx/
├── backend/                          # Backend service (Node.js/Express)
│   ├── src/
│   │   ├── server.js                 # Express server with cron jobs
│   │   └── setup/
│   │       ├── db.js                 # Database connection
│   │       ├── init.sql              # Database schema
│   │       ├── routes/               # API endpoints (/drivers, /stats)
│   │       ├── services/             # Data fetching from NYC Open Data
│   │       └── utils/                # Validation utilities
│   ├── Dockerfile                    # Multi-stage container build
│   ├── package.json
│   └── __tests__/                    # Unit tests
├── frontend/                         # Frontend service (React)
│   ├── src/
│   │   ├── components/               # React components (Charts, etc.)
│   │   ├── pages/                    # Dashboard & Search pages
│   │   └── lib/                      # API client
│   ├── Dockerfile                    # Multi-stage build with Nginx
│   └── package.json
├── platform/                         # Platform Infrastructure & Applications
│   ├── infrastructure/               # AWS core resources (Terraform)
│   │   ├── main.tf                   # EKS, VPC, RDS, ECR, S3
│   │   ├── variables.tf              # Input variables
│   │   ├── provider.tf               # AWS provider configuration
│   │   └── output.tf                 # Output values
│   ├── applications/                 # All application deployments
│   │   ├── backend/                  # Backend deployment
│   │   ├── frontend/                 # Frontend deployment
│   │   ├── argocd/                   # GitOps controller
│   │   ├── kube-prometheus-stack/    # Monitoring stack
│   │   ├── argocd-image-updater/     # Automatic image updates
│   │   ├── shared/                   # Shared resources (Ingress, etc.)
│   │   └── parent/                   # Parent ArgoCD applications
│   └── helm-release/                 # Helm deployment scripts
├── docker-compose.yml                # Local development
└── README.md
```

## 🚀 Complete Deployment Guide

This guide will walk you through deploying the entire infrastructure and application stack from scratch.

### Prerequisites

Before starting, ensure you have the following tools installed and configured:

```bash
# Required tools
- AWS CLI (configured with appropriate permissions)
- kubectl (Kubernetes command-line tool)
- Terraform (>= 1.0)
- Helm (>= 3.0)
- Docker
- Git

# Verify installations
aws --version
kubectl version --client
terraform --version
helm version
docker --version
```

### Step 1: Deploy AWS Infrastructure

The first step is to provision all AWS resources using Terraform.

#### 1.1 Configure AWS CLI

```bash
# Configure AWS CLI with your credentials
aws configure

# Verify configuration
aws sts get-caller-identity
```

#### 1.2 Deploy Core Infrastructure

Navigate to the platform infrastructure directory and deploy the core AWS resources:

```bash
cd platform/infrastructure

# Initialize Terraform
terraform init

# Apply VPC first so its outputs are fully stored in state and also avoid eks error
terraform apply -target=module.vpc

# Review the plan (optional but recommended)
terraform plan

# Apply the infrastructure (will prompt for database credentials)
terraform apply
```

**During `terraform apply`, you will be prompted to enter:**
- **Database Username**: The username for your RDS PostgreSQL instance
- **Database Password**: The password for your RDS PostgreSQL instance

**What gets deployed:**
- **EKS Cluster**: Kubernetes cluster with managed node groups
- **VPC**: Custom VPC with public/private subnets using custom module
- **RDS PostgreSQL**: Managed database instance with your provided credentials
- **ECR Repositories**: Private container registries for frontend/backend
- **S3 Bucket**: Remote state storage for Terraform
- **IAM Policies**: Service accounts and permissions
- **ACM Certificate**: SSL certificate for HTTPS
- **Security Groups**: Network security rules
- **Secrets Manager**: Database credentials automatically stored as `pg-db-secret`

#### 1.3 Update kubeconfig

After the EKS cluster is created, update your kubeconfig:

```bash
# Update kubeconfig to connect to your EKS cluster
aws eks update-kubeconfig --region eu-north-1 --name nyc-fhv-cluster

# Verify connection
kubectl get nodes
```

#### 1.4 Migrate State to S3 Bucket

After the main infrastructure is provisioned, migrate the Terraform state to the S3 bucket for encryption and protection:

```bash
# 1. Uncomment the backend S3 configuration in provider.tf
# Edit platform/infrastructure/provider.tf and uncomment the backend "s3" block

# 2. Re-initialize Terraform with the S3 backend
terraform init

# 3. When prompted, type 'yes' to migrate existing state to S3
# This will move your local state file to the encrypted S3 bucket

# 4. Verify state migration
terraform show
```

**Benefits of S3 Backend:**
- **Encryption**: State file is encrypted at rest
- **Versioning**: State file versioning for rollback capability
- **Team Collaboration**: Shared state for team members
- **Locking**: Prevents concurrent modifications

### Step 2: Deploy Helm Charts

Deploy ArgoCD and other essential services using Terraform:

```bash
cd platform/helm-release

# Initialize Terraform
terraform init

# Apply Helm releases
terraform apply
```

**What gets deployed:**
- **ArgoCD**: GitOps controller for application deployment
- **ArgoCD Image Updater**: Automatic image updates from ECR
- **kube-prometheus-stack**: Monitoring with Prometheus and Grafana
- **AWS Load Balancer Controller**: For ALB ingress
- **External Secrets Operator**: For secrets management

### Step 3: Configure ArgoCD
---

### Step 3: Configure ArgoCD

### 3.1. Install ArgoCD on EKS Cluster

ArgoCD is deployed via Helm chart as part of the infrastructure provisioning.

### 3.2. Generate SSH Key for GitHub Repository

Create an SSH key specifically for ArgoCD to access your GitHub repository:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "argocd@nyc-fhv-analytics" -f ~/.ssh/argocd_rsa

# Set proper permissions
chmod 600 ~/.ssh/argocd_rsa
chmod 644 ~/.ssh/argocd_rsa.pub
```

### 3.3. Add SSH Public Key to GitHub Repository

1. Copy the public key:
```bash
cat ~/.ssh/argocd_rsa.pub
```

2. Add the public key to your GitHub repository:
   - Go to your GitHub repository: `Isrealade/nyc_fhv_analytics-sndx`
   - Navigate to **Settings** → **Deploy keys**
   - Click **Add deploy key**
   - Title: `ArgoCD Deploy Key`
   - Key: Paste the public key content
   - Check **Allow write access** (required for ArgoCD Image Updater)
   - Click **Add key**

### 3.4. Create ArgoCD Repository Secret

Create a Kubernetes secret for ArgoCD to authenticate with your GitHub repository:

```bash
# Create the repository secret
kubectl create secret generic nyc-fhv \
  --namespace argocd \
  --from-file=sshPrivateKey=$HOME/.ssh/argocd_rsa \
  --from-literal=type=git \
  --from-literal=name=nyc-fhv \
  --from-literal=project=default \
  --from-literal=url=git@github.com:Isrealade/nyc_fhv_analytics-sndx.git

# Label the secret for ArgoCD to recognize it
kubectl label secret nyc-fhv \
  -n argocd argocd.argoproj.io/secret-type=repository --overwrite
```

### 3.5. Access ArgoCD UI to View Apps

1. Fetch ArgoCD admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

2. Port-forward ArgoCD server:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

3. Access ArgoCD UI at: `https://localhost:8080`
4. Login with username `admin` and the password from step 1

---
### Step 4: Trigger CI/CD Pipeline

#### 4.1 Manual Pipeline Trigger

Since the ECR repositories are now ready, trigger the CI/CD pipeline:

1. Go to your GitHub repository
2. Navigate to **Actions** tab
3. Select **Backend CI** workflow
4. Click **Run workflow** → **Run workflow**
5. Repeat for **Frontend CI** workflow

**What happens during CI/CD:**
- **Build**: Docker images for frontend and backend
- **Security Scan**: Trivy vulnerability scanning
- **Secret Scan**: TruffleHog secret detection
- **Code Quality**: SonarQube analysis
- **Push**: Images pushed to ECR with commit hash tags

#### 4.2 Update Image Tags

After the CI/CD pipeline completes, update the image tags in the Helm charts:

```bash
# Update backend image tag
cd platform/applications/backend
# Edit values.yaml and update the tag to the new commit hash

# Update frontend image tag  
cd platform/applications/frontend
# Edit values.yaml and update the tag to the new commit hash
```

#### 4.3 Update ACM Certificate

Update the ingress configuration to use the ACM certificate:

```bash
# Edit platform/applications/shared/ingress.yaml
# Update the certificate ARN with the one from Terraform output
```

#### 4.4 Commit and Push Changes

```bash
# Add all changes
git add .

# Commit with descriptive message
git commit -m "Update image tags and ACM certificate for production deployment"

# Push to remote repository
git push origin main
```

### Step 5: Deploy Applications via ArgoCD

#### 5.1 Deploy Root Application

```bash
cd platform/applications/parent

# Apply the infrastructure application
kubectl apply -f infrastructure-app.yaml
```
This will automatically deploy:
- **Backend service** with database connectivity
- **Frontend service** with proper API configuration
- **Monitoring stack** (Prometheus/Grafana)
- **Argocd**: ArgoCD itself (self-managed)
- **Ingress controller** with TLS certificates

### 5.2. Verify Deployment

Check that all applications are synced and healthy in the ArgoCD UI:
- All applications should show "Synced" status

**ArgoCD Image Updater** automatically updates Docker images from ECR to running deployments when new images are pushed.

#### 5.3 Monitor Deployment

Watch the applications sync in ArgoCD:
- Applications will show as **OutOfSync** initially
- Click **Sync** to start deployment
- Monitor the deployment progress
- Applications should eventually show as **Healthy**

### Step 6: Verify Production Deployment

#### 6.1 Check Application Status

```bash
# Check all pods are running
kubectl get pods -A

# Check services
kubectl get svc

# Check ingress
kubectl get ingress
```

#### 6.2 Access the Application

The application will be available through the ALB ingress at your configured domain:

- **Main URL**: `https://css.redeploy.online`
- **Frontend**: Dashboard and search interface at the root path
- **Backend API**: 
  - `https://css.redeploy.online/drivers` - Driver search and management
  - `https://css.redeploy.online/stats` - Statistics and analytics
  - `https://css.redeploy.online/health` - Health check endpoint

**Note**: The ingress uses an Application Load Balancer (ALB) with SSL/TLS termination using your ACM certificate. Make sure your domain `css.redeploy.online` is properly configured in your DNS to point to the ALB endpoint.

#### 6.3 Get ALB Endpoint

To find the ALB endpoint for DNS configuration:

```bash
# Get the ALB hostname
kubectl get ingress nyc-fhv-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or describe the ingress for more details
kubectl describe ingress nyc-fhv-ingress
```

Update your DNS CNAME record to point your domain `css.redeploy.online` to the ALB hostname.

#### 6.4 Verify SSL Certificate

```bash
# Check certificate status
kubectl describe ingress nyc-fhv-ingress
```

## 🔄 CI/CD Pipeline Details

### Backend Pipeline (`.github/workflows/ci-backend.yaml`)

**Triggers:**
- Push to `main` branch affecting `backend/` directory
- Pull requests to `main` affecting `backend/` directory

**Pipeline Steps:**
1. **Checkout Code**: Clone repository
2. **Setup Node.js**: Install Node.js 20
3. **Install Dependencies**: `npm ci`
4. **Run Tests**: Execute Jest test suite
5. **Security Scan**: TruffleHog secret detection
6. **Code Quality**: SonarQube analysis
7. **Build Docker Image**: Multi-stage build
8. **Vulnerability Scan**: Trivy security scan
9. **Push to ECR**: Tag with commit hash and push

### Frontend Pipeline (`.github/workflows/ci-frontend.yaml`)

**Triggers:**
- Push to `main` branch affecting `frontend/` directory
- Pull requests to `main` affecting `frontend/` directory

**Pipeline Steps:**
1. **Checkout Code**: Clone repository
2. **Setup Node.js**: Install Node.js 20
3. **Install Dependencies**: `npm ci`
4. **Security Scan**: TruffleHog secret detection
5. **Code Quality**: SonarQube analysis
6. **Build Docker Image**: Multi-stage build with Nginx
7. **Vulnerability Scan**: Trivy security scan
8. **Push to ECR**: Tag with commit hash and push

## 🛡️ Security Features

### Container Security
- **Non-root users**: All containers run as non-root
- **Read-only filesystems**: Immutable container filesystems
- **Minimal base images**: Alpine Linux for smaller attack surface
- **Vulnerability scanning**: Trivy scans on every build

### Network Security
- **VPC isolation**: Private subnets for database and application pods
- **Security groups**: Restrictive network access rules
- **TLS encryption**: HTTPS everywhere with ACM certificates
- **Private ECR**: Container images stored in private repositories
- **Kubernetes Network Policies**: Micro-segmentation within the cluster

### Secrets Management
- **AWS Secrets Manager**: Database credentials stored securely
- **CSI Driver**: Kubernetes secrets integration
- **No hardcoded secrets**: All sensitive data externalized
- **Rotation support**: Secrets can be rotated without code changes

## 🔒 Network Security Policies

The platform implements comprehensive Kubernetes Network Policies for micro-segmentation and defense in depth:

### **Default Deny Policy**
- **Deny All Traffic**: Blocks all ingress and egress traffic by default
- **Namespace Isolation**: Prevents unauthorized cross-namespace communication

### **Application-Specific Policies**

#### **Frontend Network Policy**
- **Ingress**: Allows traffic from ingress controllers and load balancers
- **Egress**: Only allows communication to backend services
- **Isolation**: Prevents direct database access

#### **Backend Network Policy**
- **Ingress**: Only accepts traffic from frontend services and ingress controllers
- **Egress**: Only allows communication to database services
- **API Protection**: Isolates backend from unnecessary network access

#### **Database Network Policy**
- **Ingress**: Only accepts connections from backend services
- **No Egress**: Database pods cannot initiate outbound connections
- **Data Protection**: Ensures database is only accessible by authorized services

### **System Policies**
- **DNS Resolution**: Allows DNS queries to kube-system namespace
- **Ingress Controller**: Permits traffic from AWS Load Balancer Controller
- **Monitoring**: Enables communication with Prometheus and monitoring services

### **Benefits**
- **Zero Trust**: No implicit trust between services
- **Attack Surface Reduction**: Limits lateral movement in case of compromise
- **Compliance**: Meets security requirements for production workloads
- **Micro-segmentation**: Granular control over service-to-service communication

## 📊 Monitoring & Observability

### Prometheus Stack
- **Prometheus**: Metrics collection and storage
- **Grafana**: Dashboards and visualization
- **AlertManager**: Alert routing and management
- **Node Exporter**: Node-level metrics
- **kube-state-metrics**: Kubernetes object metrics

### Key Metrics
- **Application**: Response times, error rates, request counts
- **Infrastructure**: CPU, memory, disk usage
- **Database**: Connection counts, query performance
- **Kubernetes**: Pod health, resource utilization

### Accessing Monitoring

```bash
# Port forward Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80

# Access Grafana at http://localhost:3000
# Default credentials: admin/prom-operator
```

## 🔧 Local Development

### Backend Development

```bash
cd backend
cp .env.example .env
npm install
npm run dev  # Starts on port 4000
```

### Frontend Development

```bash
cd frontend
cp .env.example .env
npm install
npm run dev  # Starts on port 5173
```

### Full Stack with Docker Compose

```bash
# Start all services locally
docker-compose up --build

# Access application
# Frontend: http://localhost:5173
# Backend: http://localhost:4000
# Database: localhost:5432
```

## 🗑️ Cleanup

### Destroy Applications

```bash
# Delete ArgoCD applications
kubectl delete -f platform/applications/parent/infrastructure-app.yaml

# Delete ArgoCD namespace
kubectl delete namespace argocd
```

### Destroy Infrastructure

```bash
# 1. Delete ingress first (to avoid ALB deletion issues)
kubectl delete ingress nyc-fhv-ingress

# 2. Destroy Helm releases
cd platform/helm-release
terraform destroy

# 3. Destroy AWS infrastructure
cd platform/infrastructure
terraform destroy
```

## 🚨 Troubleshooting

### Common Issues

1. **ArgoCD not syncing**
- Check repository connection in ArgoCD UI
- Verify Git credentials
- Check application sync policy

2. **Pods not starting**
- Check resource limits and requests
- Verify image tags in values.yaml
- Check pod logs: `kubectl logs <pod-name>`

3. **Database connection issues**
- Verify Secrets Manager configuration
- Check security group rules
- Verify RDS endpoint

4. **Ingress not working**
- Check ALB controller logs
- Verify certificate ARN
- Check DNS configuration

### Useful Commands

```bash
# Check pod status
kubectl get pods -A

# View pod logs
kubectl logs -f <pod-name> -n <namespace>

# Check ingress status
kubectl describe ingress nyc-fhv-ingress

# Check ArgoCD applications
kubectl get applications -n argocd

# Port forward services
kubectl port-forward svc/<service-name> <local-port>:<service-port>
```

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)