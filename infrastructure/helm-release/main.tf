data "aws_eks_cluster" "eks" {
  name = "css-cluster"
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.eks.name
}

# Create namespace first
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Argo CD Helm release
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.3.6" 

  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    },

    {
      name  = "configs.cm.application.instanceLabelKey"
      value = "argocd-app"
    },
  ]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "77.6.1"
}