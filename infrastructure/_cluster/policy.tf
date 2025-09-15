data "aws_caller_identity" "current" {
}

# resource "aws_iam_policy" "policy" {
#   name        = "secret-manager"
#   path        = "/"
#   description = "Policy for cluster secrets"
#   policy = jsonencode(
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
#             "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.id}:secret:db_username",
#             "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.id}:secret:db_password"
#             # "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.id}:secret:secretName3-AbCdEf"
#           ]
#         }
#       ]
#     }
#   )
# }


# resource "aws_iam_role" "secret-manager" {
#   name        = "secret-manager-role"
#   description = "The secret manager role for the cluster"
#   assume_role_policy = jsonencode(
#     {
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Effect = "Allow"
#           Principal = {
#             Federated = module.eks.oidc_provider_arn
#           }
#           Action = "sts:AssumeRoleWithWebIdentity"
#           Condition = {
#             StringEquals = {
#               "${module.eks.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
#               "${module.eks.cluster_oidc_issuer_url}:aud" = "sts.amazonaws.com"
#             }
#           }
#         }
#       ]
#     }
#   )
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
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${module.eks.cluster_oidc_issuer_url}:aud" = "sts.amazonaws.com"
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

resource "aws_iam_policy" "argocd_image_updater_ecr" {
  name        = "argocd-image-updater-policy"
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

resource "aws_iam_role" "argocd_image_updater" {
  name        = "argocd-image-updater"
  description = "ArgoCD image updater role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.cluster_oidc_issuer_url
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:argocd:argocd-image-updater",
            "${module.eks.cluster_oidc_issuer_url}:aud" : "sts.amazonaws.com"
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