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

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# resource "aws_iam_openid_connect_provider" "oidc" {
#   client_id_list  = ["sts.amazonaws.com"]
#   url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

#   depends_on = [module.eks]
# }


resource "aws_iam_policy" "alb_controller" {
  name        = "eks-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "iam:CreateServiceLinkedRole"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:Describe*",
            "elasticloadbalancing:Describe*"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "acm:ListCertificates",
            "acm:DescribeCertificate"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:DeleteTags",
            "ec2:DeleteSecurityGroup"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:DeleteRule",
            "elasticloadbalancing:ModifyRule",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "wafv2:GetWebACL",
            "wafv2:GetWebACLForResource",
            "wafv2:AssociateWebACL",
            "wafv2:DisassociateWebACL",
            "wafv2:ListWebACLs",
            "wafv2:ListResourcesForWebACL"
          ],
          "Resource" : "*"
        }
      ]
    }

  )
}

resource "aws_iam_role" "alb_controller" {
  name = "eks-alb-controller"

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
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}

resource "aws_iam_policy" "argocd_image_updater_ecr" {
  name        = "ArgoCDImageUpdaterECRPolicy"
  description = "Policy for ArgoCD Image Updater to access ECR"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
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
  url = module.eks.cluster_oidc_issuer_url

  depends_on = [module.eks]
}

resource "aws_iam_role" "argocd_image_updater" {
  name = "argocd-image-updater"

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
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:argocd:argocd-image-updater",
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" : "sts.amazonaws.com"
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