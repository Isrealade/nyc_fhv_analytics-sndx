# ===== Global =====
region      = "eu-north-1"
environment = "production"
project     = "css-app"

tags = {
  Terraform = "true"
}

# ===== S3 Bucket =====
s3_bucket_config = {
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
    tier = "remote-state"
  }
}

# ===== VPC =====
vpc_name             = "css-vpc"
vpc_cidr             = "10.0.0.0/16"
public_subnet_count  = 3
private_subnet_count = 3
enable_nat           = true
single_nat           = true
create_db_subnet     = true
db_subnet_group_name = "css-db_subnet_group"

# ===== EKS =====
eks_cluster_name       = "css-cluster"
kubernetes_version     = "1.33"
endpoint_public_access = true

# ===== ECR =====
repositories = [
  "frontend-service",
  "backend-service"
]

# ===== RDS =====
db_identifier        = "css-db"
db_engine            = "postgres"
db_engine_version    = "17.4"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_storage_type      = "gp3"
db_name              = "fhv"
db_port              = 5432

# ===== ACM =====
domain_name = "css.redeploy.online"