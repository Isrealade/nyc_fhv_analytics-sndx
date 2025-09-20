#########################
# S3 Bucket
#########################
module "s3_bucket" {
  source  = "Isrealade/s3-bucket/aws"
  version = "1.1.2"

  s3 = {
    bucket              = var.s3.bucket_name
    force_destroy       = var.s3.force_destroy
    object_lock_enabled = var.s3.object_lock_enabled
    acl                 = var.s3.acl
  }

  versioning = {
    enabled    = var.s3.versioning_enabled
    mfa_delete = var.s3.mfa_delete
  }

  encryption = {
    enabled         = var.s3.encryption_enabled
    sse_algorithm   = var.s3.sse_algorithm
    create_kms_key  = var.s3.create_kms_key
    key_rotation    = var.s3.key_rotation
    deletion_window = var.s3.deletion_window
  }

  tags = merge(var.tags, var.s3.tags)
}


#########################
# VPC
#########################
module "vpc" {
  source  = "Isrealade/vpc/aws"
  version = "2.1.0"

  name                 = var.vpc.name
  cidr                 = var.vpc.cidr
  instance_tenancy     = var.vpc.instance_tenancy
  enable_dns_support   = var.vpc.enable_dns_support
  enable_dns_hostnames = var.vpc.enable_dns_hostnames
  private_ip_map       = var.vpc.private_ip_map

  # public_subnet = var.vpc.public_subnet
  # private_subnet = var.vpc.private_subnet
  public_subnet_count  = var.vpc.public_subnet_count
  private_subnet_count = var.vpc.private_subnet_count

  enable_nat = var.vpc.enable_nat
  single_nat = var.vpc.single_nat
  # one_nat_per_az = var.vpc.one_nat_per_az

  create_db_subnet  = var.vpc.create_db_subnet
  subnet_group_name = var.vpc.db_subnet_group_name

  db_subnet_group_tags = merge(var.tags, var.vpc.db_subnet_group_tags)

  ingress = var.vpc.ingress
  # custom_ingress = var.vpc.custom_ingress

  public_subnet_tags = var.vpc.public_subnet_tags

  private_subnet_tags = var.vpc.private_subnet_tags

  tags = merge(var.tags, var.vpc.tags)
}

#########################
# EKS
#########################
module "eks" {
  source     = "terraform-aws-modules/eks/aws"
  version    = "~> 21.0"
  depends_on = [module.vpc]

  name                                     = var.eks.cluster_name
  kubernetes_version                       = var.eks.kubernetes_version
  endpoint_public_access                   = var.eks.endpoint_public_access
  enable_cluster_creator_admin_permissions = var.eks.enable_cluster_creator_admin_permissions
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  control_plane_subnet_ids                 = module.vpc.private_subnet_ids
  eks_managed_node_groups                  = var.eks.eks_managed_node_groups

  addons = var.eks.addons

  tags = merge(var.tags, var.eks.tags
  )
}

#########################
# ECR Repositories
#########################
module "ecr" {
  source   = "terraform-aws-modules/ecr/aws"
  version  = "3.0.1"
  for_each = toset(var.ecr.repositories)

  repository_name               = each.value
  repository_type               = var.ecr.repository_type
  repository_force_delete       = var.ecr.repository_force_delete
  repository_image_scan_on_push = var.ecr.repository_image_scan_on_push

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = { type = "expire" }
      }
    ]
  })

  manage_registry_scanning_configuration = var.ecr.manage_registry_scanning_configuration
  registry_scan_type                     = var.ecr.registry_scan_type

  tags = merge(var.tags, var.ecr.tags)
}

#########################
# RDS
#########################

### RDS Security Group Rule
resource "aws_security_group" "rds_sg" {
  vpc_id     = module.vpc.vpc_id
  depends_on = [module.vpc, module.eks]

  tags = merge(var.tags, var.db.security_group_tags)
}

resource "aws_vpc_security_group_ingress_rule" "rds_sg" {
  referenced_security_group_id = module.eks.node_security_group_id
  security_group_id            = aws_security_group.rds_sg.id
  from_port                    = var.db.port
  ip_protocol                  = "tcp"
  to_port                      = var.db.port
}

### RDS 
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier        = var.db.identifier
  engine            = var.db.engine
  engine_version    = var.db.engine_version
  instance_class    = var.db.instance_class
  allocated_storage = var.db.allocated_storage
  storage_type      = var.db.storage_type

  create_db_instance        = var.db.create_db_instance
  create_db_parameter_group = var.db.create_db_parameter_group
  create_db_option_group    = var.db.create_db_option_group
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]

  iam_database_authentication_enabled = var.db.iam_database_authentication_enabled
  create_monitoring_role              = var.db.create_monitoring_role

  db_subnet_group_name = module.vpc.db_subnet_group_name

  db_name  = var.db.db_name
  username = var.db.username
  password = var.db.password
  port     = var.db.port

  deletion_protection = false

  tags = merge(var.tags, var.db.tags)
}

#########################
# Secrets Manager
#########################
resource "aws_secretsmanager_secret" "secret" {
  name        = "pg-db-secret"
  description = "PostgreSQL credentials for backend"

  depends_on = [module.eks]
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    PGUSER     = var.db.username
    PGPASSWORD = var.db.password
  })
}

#########################
# ACM Certificate
#########################
resource "aws_acm_certificate" "cert" {
  domain_name       = var.acm.domain_name
  validation_method = var.acm.validation_method

  tags = merge(var.tags, var.acm.tags)
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}