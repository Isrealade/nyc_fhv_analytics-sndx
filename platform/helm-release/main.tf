# Create namespace first
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "calico-systems" {
  metadata {
    name = "calico-systems"
  }
}

resource "kubernetes_service_account" "secret-manager" {
  metadata {
    name      = "secret-manager"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.secret-manager.arn
    }
  }
}

resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.alb_controller.arn
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.1"

  values = [
    yamlencode({
      clusterName = data.aws_eks_cluster.eks.name
      vpcId       = data.aws_eks_cluster.eks.vpc_config[0].vpc_id
      enableWaf   = false
      enableWafv2 = false
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.alb_controller.metadata[0].name
      }
    })
  ]

  depends_on = [
    kubernetes_service_account.alb_controller
  ]
}

resource "helm_release" "csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.0"
  namespace  = "kube-system"

  set = [{
    name  = "syncSecret.enabled"
    value = "true"
    }
  ]
}

resource "helm_release" "csi_aws_provider" {
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  # version    = "2.0.0 "
  namespace = "kube-system"
}

resource "helm_release" "calico" {
  name       = "calico"
  namespace  = kubernetes_namespace.calico-systems.metadata[0].name
  repository = "https://docs.tigera.io/calico/charts"
  chart      = "tigera-operator"
  version    = "v3.30.3"

  depends_on = [kubernetes_namespace.calico-systems]
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

  depends_on = [kubernetes_namespace.argocd]
}