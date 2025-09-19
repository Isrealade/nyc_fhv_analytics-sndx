# NYC FHV Analytics Dashboard

A full-stack analytics platform for NYC For-Hire Vehicle (FHV) driver data, built with modern DevOps practices. The platform features containerized services, CI/CD pipelines, GitOps deployment via ArgoCD on EKS, and comprehensive monitoring.

## 🏗️ Architecture

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

**Components:**
- **Frontend**: React app with Tailwind CSS, served by Nginx
- **Backend**: Node.js/Express API with PostgreSQL
- **Database**: AWS RDS PostgreSQL (managed)
- **Infrastructure**: AWS EKS, VPC, ALB, Secrets Manager
- **GitOps**: ArgoCD with Image Updater
- **Monitoring**: Prometheus, Grafana, AlertManager

## 📁 Project Structure

```
nyc_fhv_analytics-sndx/
├── backend/                          # Backend service
│   ├── src/
│   │   ├── server.js                 # Express server
│   │   └── setup/
│   │       ├── db.js                 # Database connection
│   │       ├── init.sql              # Database schema
│   │       ├── routes/               # API endpoints
│   │       ├── services/             # Data fetching & processing
│   │       └── utils/                # Validation utilities
│   ├── Dockerfile
│   └── package.json
├── frontend/                         # Frontend service
│   ├── src/
│   │   ├── components/               # React components
│   │   ├── pages/                    # Dashboard & Search pages
│   │   └── lib/                      # API client
│   ├── Dockerfile
│   └── package.json
├── infrastructure/                   # Infrastructure as Code
│   ├── _cluster/                     # Terraform for AWS resources
│   │   ├── main.tf                   # EKS, VPC, RDS
│   │   ├── variables.tf              # Input variables
│   │   └── terraform.tfstate         # State file
│   ├── charts/                       # Helm charts
│   │   ├── backend/                  # Backend deployment
│   │   ├── frontend/                 # Frontend deployment
│   │   ├── argocd/                   # GitOps controller
│   │   ├── kube-prometheus-stack/    # Monitoring stack
│   │   └── shared/                   # Shared resources
│   └── helm-release/                 # Helm deployment scripts
├── docker-compose.yml                # Local development
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- AWS CLI configured
- kubectl
- Terraform
- Helm

### Local Development
```bash
# Clone repository
git clone <repository-url>
cd nyc_fhv_analytics-sndx

# Start all services
docker-compose up --build

# Access application
# Frontend: http://localhost:5173
# Backend: http://localhost:4000
# Database: localhost:5432
```

## 🏢 Infrastructure Provisioning

### 1. AWS Resources (Terraform)
```bash
cd infrastructure/_cluster

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=plan.tfplan

# Apply infrastructure
terraform apply plan.tfplan
```

**Creates:**
- EKS cluster with managed node groups
- VPC with public/private subnets
- RDS PostgreSQL instance
- Security groups and IAM roles
- S3 bucket for Terraform state

### 2. Kubernetes Applications (Helm)
```bash
cd infrastructure/helm-release

# Deploy applications
terraform init
terraform apply
```

**Deploys:**
- ArgoCD for GitOps
- Backend and Frontend services
- Monitoring stack (Prometheus/Grafana)
- Ingress controller and TLS certificates

## 🔐 Secrets Management

### AWS Secrets Manager
Store database credentials in AWS Secrets Manager:

```json
{
  "dbhost": "your-rds-endpoint.amazonaws.com",
  "dbport": "5432",
  "dbusername": "your-username",
  "dbpassword": "your-password",
  "dbname": "fhv"
}
```

### CSI Driver Integration
The backend uses AWS Secrets Store CSI driver to mount secrets:

```yaml
# SecretProviderClass
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: database_secret
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "pg-db-secret"
        objectType: "secretsmanager"
```

## 🌐 Networking & Ingress

### ALB Configuration
- **Host**: `css.redeploy.online`
- **TLS**: ACM certificate
- **Routes**:
  - `/` → Frontend service
  - `/drivers`, `/stats` → Backend service

### Security Groups
- ALB: Allows HTTPS (443) from internet
- EKS Nodes: Allows traffic from ALB
- RDS: Allows PostgreSQL (5432) from EKS nodes only

## 📊 Monitoring & Observability

### Prometheus Stack
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **AlertManager**: Alert routing and management

### Key Metrics
- Kubernetes cluster health
- Application performance
- Database connections
- API response times

## 🔄 CI/CD Pipeline

### GitHub Actions
- **Build**: Docker images for frontend/backend
- **Scan**: Security scanning with Trivy and TruffleHog
- **Test**: Unit tests and code quality checks
- **Deploy**: Push to ECR, ArgoCD syncs to cluster

### ArgoCD Image Updater
Automatically updates deployments when new images are pushed to ECR.

## 🛠️ Development

### Backend Development
```bash
cd backend
npm install
npm run dev  # Starts on port 4000
```

### Frontend Development
```bash
cd frontend
npm install
npm run dev  # Starts on port 5173
```

### Database Schema
The application uses PostgreSQL with the following key tables:
- `drivers`: FHV driver records
- `driver_trends`: Historical statistics
- `meta`: Application metadata

## 🔧 Configuration

### Environment Variables
- `VITE_API_BASE_URL`: Frontend API endpoint
- `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`: Database connection
- `SOCRATA_APP_TOKEN`: NYC Open Data API token (optional)

### Build Arguments
For production builds, pass the correct API URL:
```bash
docker build --build-arg VITE_API_BASE_URL=https://css.redeploy.online frontend
```

## 📈 Scaling

### Horizontal Pod Autoscaler
- **Backend**: 2-4 replicas based on CPU/memory
- **Frontend**: 2-4 replicas based on CPU/memory

### Database
- RDS instance can be scaled vertically
- Consider read replicas for high read workloads

## 🔒 Security

### Best Practices
- Least privilege IAM roles
- Network segmentation with security groups
- Encrypted storage (RDS, EBS)
- Regular security scanning
- Secrets rotation

### Compliance
- AWS Well-Architected Framework
- Kubernetes security best practices
- Container image scanning

## 🚨 Troubleshooting

### Common Issues
1. **Frontend calls localhost in production**
   - Solution: Rebuild with correct `VITE_API_BASE_URL`

2. **Backend cannot connect to database**
   - Check Secrets Manager configuration
   - Verify security group rules

3. **ALB not created**
   - Ensure AWS Load Balancer Controller is installed
   - Check IAM permissions

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Helm Documentation](https://helm.sh/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with Docker Compose
5. Submit a pull request