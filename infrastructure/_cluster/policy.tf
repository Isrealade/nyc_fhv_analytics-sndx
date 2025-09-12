# resource "aws_iam_policy" "policy" {
#   name        = "secret-manager"
#   path        = "/"
#   description = "My test policy"
#   policy = jsondecode(
#     {
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Effect" : "Allow",
#           "Action" : [
#             "secretsmanager:BatchGetSecretValue",
#             "secretsmanager:ListSecrets"
#           ],
#           "Resource" : "*"
#         },
#         {
#           "Effect" : "Allow",
#           "Action" : [
#             "secretsmanager:GetSecretValue",
#             "secretsmanager:DescribeSecret"
#           ],
#           "Resource" : [
#             "arn:aws:secretsmanager:us-east-1:123456789012:secret:secretName1-AbCdEf",
#             "arn:aws:secretsmanager:us-east-1:123456789012:secret:secretName2-AbCdEf",
#             "arn:aws:secretsmanager:us-east-1:123456789012:secret:secretName3-AbCdEf"
#           ]
#         }
#       ]
#     }
#   )
# }

# data "aws_eks_cluster" "eks" {
#   name = "css-cluster"
# }

# data "aws_eks_cluster_auth" "eks" {
#   name = "css-cluster"
# }

# locals {
#   # OIDC provider host string used in trust condition (no https://)
#   oidc_sub_prefix = replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
# }

# # Create the OIDC provider (skip if already created via eksctl)
# resource "aws_iam_openid_connect_provider" "eks" {
#   url             = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
#   client_id_list  = ["sts.amazonaws.com"]
# }

resource "aws_iam_policy" "argocd_image_updater_ecr" {
  name        = "ArgoCDImageUpdaterECRPolicy"
  description = "Policy for ArgoCD Image Updater to access ECR"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_iam_openid_connect_provider" "eks" {
#   url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_role" "argocd_image_updater" {
  name = "ArgoCDImageUpdaterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:argocd:argocd-image-updater"
          }
        }
      }
    ]
  })
}

# Attach the ECR policy
resource "aws_iam_role_policy_attachment" "argocd_image_updater_attach" {
  role       = aws_iam_role.argocd_image_updater.name
  policy_arn = aws_iam_policy.argocd_image_updater_ecr.arn
}