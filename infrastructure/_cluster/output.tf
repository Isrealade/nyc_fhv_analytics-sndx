#########################
# Outputs
#########################
output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
}

output "db_endpoint" {
  value = module.db.db_instance_endpoint
}

output "oidc_url" {
  value = module.eks.cluster_oidc_issuer_url
}