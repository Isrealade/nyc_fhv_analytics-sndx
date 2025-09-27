#########################
# IAM Roles & Policies
#########################
resource "aws_iam_policy" "secret_manager_policy" {
  name        = "secret-manager"
  path        = "/"
  description = "Policy for cluster secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:BatchGetSecretValue",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:pg-db-secret*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "secret_manager" {
  name        = "secret-manager"
  description = "The secret manager role for the cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = module.eks.oidc_provider_arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_url_arn}:sub" = "system:serviceaccount:default:secret-manager"
            "${local.oidc_url_arn}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secret_manager_attach" {
  role       = aws_iam_role.secret_manager.name
  policy_arn = aws_iam_policy.secret_manager_policy.arn
}

# --- ALB Controller ---
resource "aws_iam_policy" "alb_controller" {
  name        = "eks-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/alb-controller.json")
}

resource "aws_iam_role" "alb_controller" {
  name = "eks-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = module.eks.oidc_provider_arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_url_arn}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${local.oidc_url_arn}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  depends_on = [module.eks]
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}

# --- ArgoCD Image Updater ---
resource "aws_iam_policy" "argocd_image_updater_ecr" {
  name        = "argocd-image-updater-policy"
  description = "Policy for ArgoCD Image Updater to access ECR"
  policy      = file("${path.module}/policies/image-updater.json")
}

resource "aws_iam_role" "argocd_image_updater" {
  name        = "argocd-image-updater"
  description = "ArgoCD image updater role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = module.eks.oidc_provider_arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_url_arn}:sub" = "system:serviceaccount:argocd:argocd-image-updater"
            "${local.oidc_url_arn}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd_image_updater_attach" {
  role       = aws_iam_role.argocd_image_updater.name
  policy_arn = aws_iam_policy.argocd_image_updater_ecr.arn
}