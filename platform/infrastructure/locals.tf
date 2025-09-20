data "aws_caller_identity" "current" {}

locals {
  oidc_url_arn = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}