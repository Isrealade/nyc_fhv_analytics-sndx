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

