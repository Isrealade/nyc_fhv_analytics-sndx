data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  vpc_name   = var.vpc.name
  region = var.region

  vpc_cidr = var.vpc.cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  oidc_url_arn = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}