# NYCAD Analytics Dashboard

**NYCAD Analytics Dashboard** is a full-stack analytics platform for NYC taxi data, built with modern DevOps practices. The platform features containerized frontend and backend services, CI/CD pipelines to AWS ECR, GitOps deployment via ArgoCD on EKS, secure secrets management using AWS Secrets Manager, and monitoring with Prometheus & Grafana.

---

## Tech Stack

* **Frontend:** React + Tailwind CSS
* **Backend:** Node.js + Express + PostgreSQL
* **Infrastructure:** AWS EKS, RDS, S3, VPC
* **CI/CD:** GitHub Actions, Docker, Trivy, SonarQube, TruffleHog
* **GitOps:** ArgoCD, ArgoCD Image Updater
* **Monitoring:** kube-prometheus-stack, Grafana

---

## Architecture Overview

```
+-------------+        +------------------+       +------------------+
| Frontend    | ---->  | Ingress (EKS)    | --->  | Backend (EKS)    |
| React App   |        | nyc-fhv-ingress  |       | Node.js/Express  |
+-------------+        +------------------+       +------------------+
                                                         |
                                                         v
                                                 +----------------+
                                                 | RDS Postgres   |
                                                 | pg-db-secret   |
                                                 +----------------+

 ArgoCD Image Updater automatically updates images from AWS ECR
 Monitoring via Prometheus & Grafana
```

---

## Project Structure

```
NYCAD-Analytics-Dashboard/
├── .gitignore
├── README.md
├── docker-compose.yml
├── sonar-project.properties

├── .github/
│   └── workflows/
│       ├── ci-backend.yaml            # CI/CD pipeline for backend
│       └── ci-frontend.yaml           # CI/CD pipeline for frontend

├── backend/                           # Backend service (Node.js/Express)
│   ├── .dockerignore
│   ├── .env.example
│   ├── Dockerfile
│   ├── jest.config.js
│   ├── package.json
│   ├── __tests__/utils.test.js
│   └── src/
│       ├── server.js
│       └── setup/
│           ├── routes/
│           │   ├── drivers.js
│           │   └── stats.js
│           ├── services/
│           │   ├── fetchAndStore.js
│           │   └── populateTrends.js
│           ├── utils/validation.js
│           ├── db.js
│           └── init.sql

├── frontend/                          # Frontend service (React)
│   ├── .dockerignore
│   ├── .env.example
│   ├── Dockerfile
│   ├── index.html
│   ├── package.json
│   ├── postcss.config.js
│   ├── tailwind.config.js
│   ├── vite.config.js
│   └── src/
│       ├── App.jsx
│       ├── main.jsx
│       ├── styles.css
│       ├── lib/api.js
│       ├── components/
│       │   ├── BoroughChart.jsx
│       │   └── TrendChart.jsx
│       └── pages/
│           ├── Dashboard.jsx
│           └── Search.jsx

├── infrastructure/                     # Cluster provisioning & Helm charts
│   ├── _cluster/                        # Terraform scripts for AWS resources
│   │   ├── provider.tf
│   │   └── variables.tf
│   ├── charts/                           # Helm charts for apps & monitoring
│   │   ├── argocd/
│   │   ├── backend/
│   │   ├── frontend/
│   │   ├── kube-prometheus-stack/
│   │   └── argocd-image-updater/
│   └── helm-release/                     # Scripts to deploy Helm charts
```

---

## Local Development

### Backend

```bash
cd backend
cp .env.example .env
npm install
npm run seed   # optional: one-time data sync
npm run dev    # http://localhost:4000
```

### Frontend

```bash
cd frontend
cp .env.example .env
npm install
npm run dev    # http://localhost:5173
```

### Full Stack with Docker Compose

```bash
docker-compose up --build
```

* Frontend: [http://localhost:5173](http://localhost:5173)
* Backend: [http://localhost:4000](http://localhost:4000)
* Postgres: localhost:5432

---

## Continuous Integration / Deployment

### Frontend CI (`.github/workflows/ci-frontend.yaml`)

* Triggered on push or PR affecting `frontend/`.
* Steps:

  1. Install dependencies and cache `node_modules`.
  2. Lint & test.
  3. Secret scanning via TruffleHog.
  4. SonarQube analysis.
  5. Build Docker image and scan with Trivy.
  6. Push image to **AWS ECR**.

### Backend CI (`.github/workflows/ci-backend.yaml`)

* Triggered on push or PR affecting `backend/`.
* Steps:

  1. Install dependencies and cache `node_modules`.
  2. Lint & test with Postgres service.
  3. Secret scanning via TruffleHog.
  4. SonarQube analysis.
  5. Build Docker image and scan with Trivy.
  6. Push image to **AWS ECR**.

---

## AWS Setup

### Secrets Manager

* Create a secret for the database:

```
Secret Name: pg-db-secret
Keys:
  - dbusername
  - dbpassword
```

* Backend service retrieves credentials from this secret.

### Terraform Infrastructure

* Provision resources using `_cluster/` Terraform:

  * EKS cluster
  * RDS Postgres
  * S3 bucket (for remote state)
  * Private VPC using custom module
* After provisioning, Helm charts deploy services to the cluster.

---

## ArgoCD Setup & Deployment

1. Install ArgoCD on the EKS cluster.
2. Fetch ArgoCD admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

3. Port-forward ArgoCD server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

4. Login using admin credentials.
5. Connect your Git repository in ArgoCD.
6. Deploy apps from `infrastructure/charts/rootapps`:

```bash
cd infrastructure/charts/rootapps
kubectl apply -f infrastructure-app.yaml
```

* App of Apps pattern: all services will be deployed and monitored automatically.
* Services: `frontend`, `backend`
* Ingress: `nyc-fhv-ingress`

**ArgoCD Image Updater** automatically updates Docker images from ECR to running deployments.

---

## Monitoring

* **Prometheus** and **Grafana** deployed via `kube-prometheus-stack`.
* Metrics are collected for cluster and services.
* Dashboards are accessible through Grafana (port-forward or ingress).

---

## Destroying the Cluster & Services

1. Disconnect repository from ArgoCD.
2. Delete the `argocd` namespace:

```bash
kubectl delete ns argocd
```

3. Delete all deployments in `default` namespace:

```bash
kubectl delete deploy frontend backend
kubectl delete svc frontend backend
```

4. Delete the ingress:

```bash
kubectl delete ingress nyc-fhv-ingress
```

5. Optionally, destroy Terraform infrastructure to remove EKS, RDS, VPC, and S3 resources.

---