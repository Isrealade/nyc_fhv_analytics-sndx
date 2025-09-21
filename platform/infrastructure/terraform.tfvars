# ===== Global =====
region = "eu-north-1"

account_id = "501818865030"
partition  = "aws"

tags = {
  Project     = "css-app"
  Environment = "prod"
  Terraform   = "true"
}

# ===== S3 Bucket =====
s3 = {
  bucket_name         = "css-bucket"
  force_destroy       = true
  object_lock_enabled = true
  acl                 = "private"
  versioning_enabled  = true
  mfa_delete          = false
  encryption_enabled  = true
  sse_algorithm       = "aws:kms"
  create_kms_key      = true
  key_rotation        = true
  deletion_window     = 7

  tags = {
    Purpose = "remote-state"
  }
}

# ===== VPC =====
vpc = {
  name                 = "css-vpc"
  cidr                 = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  private_ip_map       = false

  public_subnet_count  = 3
  private_subnet_count = 3
  enable_nat           = true
  single_nat           = true
  # one_nat_per_az = false

  create_db_subnet     = true
  db_subnet_group_name = "css-subnet_group"
  db_subnet_group_tags = {}

  public_subnet_tags  = {}
  private_subnet_tags = {}

  ingress = ["https", "postgresql"]
  # custom_ingress = {}

  tags = {
    Environment = "dev"
    Owner       = "Isreal"
  }
}


# ===== EKS =====
eks = {
  cluster_name                             = "my-cluster"
  kubernetes_version                       = "1.33"
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true
  create_security_group                    = true
  create_node_security_group               = true

  # Managed Node Group configuration
  # eks_managed_node_groups = {
  #   example = {
  #     ami_type       = "AL2023_x86_64_STANDARD"
  #     instance_types = ["m6i.large"]
  #     min_size       = 1
  #     max_size       = 6
  #     desired_size   = 2
  #   }
  # }

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_class             = "STANDARD" ## or `INFREQUENT_ACCESS`
  cloudwatch_log_group_retention_in_days = 7
  cloudwatch_log_group_tags              = {}
  enabled_log_types                      = ["audit", "api", "authenticator"]

  # Addons
  addons = {
    kube-proxy         = {}
    eks-pod-identity-agent = { before_compute = true }
    vpc-cni            = { before_compute = true }
    aws-ebs-csi-driver = { preserve = false }
    coredns            = { preserve = false }
    metrics-server     = { preserve = false }
  }

  tags = {}
}

# ===== ECR =====
ecr = {
  repositories                           = ["frontend-service", "backend-service"]
  repository_type                        = "private"
  repository_force_delete                = false
  repository_image_scan_on_push          = true
  manage_registry_scanning_configuration = false
  registry_scan_type                     = "STANDARD"

  tags = {}
}

# ===== RDS =====
db = {
  identifier                          = "css-db"
  engine                              = "postgres"
  engine_version                      = "17.4"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 20
  storage_type                        = "gp3"
  create_db_instance                  = true
  create_db_parameter_group           = false
  create_db_option_group              = false
  iam_database_authentication_enabled = false
  db_name                             = "fhv"
  port                                = 5432
  deletion_protection                 = false

  create_monitoring_role                 = true
  cloudwatch_log_group_class             = "STANDARD"
  cloudwatch_log_group_retention_in_days = 7
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_skip_destroy      = false
  cloudwatch_log_group_tags              = {}
  enabled_cloudwatch_logs_exports        = ["postgresql", "upgrade", "slowquery"]
  database_insights_mode                 = "standard"
  monitoring_interval                    = 60

  security_group_tags = {
    "app"     = "rds-db"
    "Purpose" = "security group"
  }
  tags = {}
}

# ===== Secret Manager =====
secret-manager = {
  name        = "pg-db-secret"
  description = "RDS Secret"
}

# ===== ACM =====
acm = {
  domain_name       = "css.redeploy.online"
  validation_method = "DNS"

  tags = {}
}