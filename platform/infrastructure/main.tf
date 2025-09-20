#########################
# VPC
#########################
module "vpc" {
  source  = "Isrealade/vpc/aws"
  version = "2.1.0"

  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  private_ip_map       = false

  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count

  enable_nat = var.enable_nat
  single_nat = var.single_nat

  create_db_subnet  = var.create_db_subnet
  subnet_group_name = var.db_subnet_group_name

  db_subnet_group_tags = merge(var.tags, {
    Environment = var.environment
    Purpose     = "RDS"
  })

  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  ingress = ["https", "kube", "postgresql"]

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
  })
}

#########################
# EKS
#########################
module "eks" {
  source     = "terraform-aws-modules/eks/aws"
  version    = "~> 21.0"
  depends_on = [module.vpc]

  name                                     = var.eks_cluster_name
  kubernetes_version                       = var.kubernetes_version
  endpoint_public_access                   = var.endpoint_public_access
  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group              = false
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  upgrade_policy = {
    support_type = "STANDARD"
  }

  addons = {
    aws-ebs-csi-driver       = { preserve = false }
    coredns                  = { preserve = false }
    metrics-server           = { preserve = false }
    kube-state-metrics       = { preserve = false }
    prometheus-node-exporter = { preserve = false }
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
  })
}

#########################
# S3 Bucket
#########################
module "s3_bucket" {
  source  = "Isrealade/s3-bucket/aws"
  version = "1.1.2"

  s3 = {
    bucket              = var.s3_bucket_config.bucket_name
    force_destroy       = var.s3_bucket_config.force_destroy
    object_lock_enabled = var.s3_bucket_config.object_lock_enabled
    acl                 = var.s3_bucket_config.acl
  }

  versioning = {
    enabled    = var.s3_bucket_config.versioning_enabled
    mfa_delete = var.s3_bucket_config.mfa_delete
  }

  encryption = {
    enabled         = var.s3_bucket_config.encryption_enabled
    sse_algorithm   = var.s3_bucket_config.sse_algorithm
    create_kms_key  = var.s3_bucket_config.create_kms_key
    key_rotation    = var.s3_bucket_config.key_rotation
    deletion_window = var.s3_bucket_config.deletion_window
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
  })
}

#########################
# ECR Repositories
#########################
module "ecr" {
  source   = "terraform-aws-modules/ecr/aws"
  version  = "3.0.1"
  for_each = toset(var.repositories)

  repository_name               = each.value
  repository_type               = "private"
  repository_force_delete       = true
  repository_image_scan_on_push = true

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

  manage_registry_scanning_configuration = true
  registry_scan_type                     = "ENHANCED"

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = each.value
  })
}

#########################
# RDS
#########################
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier        = var.db_identifier
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = var.db_storage_type

  create_db_instance        = true
  create_db_parameter_group = false
  create_db_option_group    = false
  vpc_security_group_ids    = [module.vpc.security_group_id]

  iam_database_authentication_enabled = false
  create_monitoring_role              = false

  # create_db_subnet     = false
  db_subnet_group_name = module.vpc.db_subnet_group_name

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  deletion_protection = false

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
  })
}

#########################
# Secrets Manager
#########################
resource "aws_secretsmanager_secret" "pg" {
  name        = "pg-db-secret"
  description = "PostgreSQL credentials for backend"

  depends_on = [module.eks, module.database]
}

resource "aws_secretsmanager_secret_version" "pg_values" {
  secret_id = aws_secretsmanager_secret.pg.id
  secret_string = jsonencode({
    PGUSER     = var.db_username
    PGPASSWORD = var.db_password
  })
}

#########################
# ACM Certificate
#########################
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = "${var.project}-cert"
  })
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}