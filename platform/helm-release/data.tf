data "aws_eks_cluster" "eks" {
  name = "css-cluster"
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.eks.name
}

data "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
}

data "aws_iam_role" "secret-manager" {
  name = "secret-manager"
}

data "aws_iam_role" "alb_controller" {
  name = "eks-alb-controller"
}
