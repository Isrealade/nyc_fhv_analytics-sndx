############################
# Global
############################
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

#########################
# S3 Bucket Variables
#########################

variable "s3" {
  description = "Configuration for the S3 bucket"
  type = object({
    bucket_name         = string
    force_destroy       = bool
    object_lock_enabled = bool
    acl                 = string
    versioning_enabled  = bool
    mfa_delete          = bool
    encryption_enabled  = bool
    sse_algorithm       = string
    create_kms_key      = bool
    key_rotation        = bool
    deletion_window     = number
    environment         = string
    project             = string
    tags                = map(string)
  })
}

############################
# VPC
############################
variable "vpc" {
  description = "Configuration for VPC module."
  type = object({
    name                 = string
    cidr                 = string
    instance_tenancy     = string
    enable_dns_support   = bool
    enable_dns_hostnames = bool
    private_ip_map       = bool

    # public_subnet = optional(list(string))
    # private_subnet = optional(list(string))
    public_subnet_count  = number
    private_subnet_count = number
    enable_nat           = bool
    single_nat           = bool
    # one_nat_per_az = bool

    create_db_subnet     = bool
    db_subnet_group_name = string
    db_subnet_group_tags = map(string)

    ingress = list(string)
    # custom_ingress = optional(object)

    public_subnet_tags  = map(string)
    private_subnet_tags = map(string)
    tags                = map(string)
  })
}


############################
# EKS
############################
variable "eks" {
  description = "Configuration for EKS"
  type = object({
    cluster_name                             = string
    kubernetes_version                       = string
    endpoint_public_access                   = bool
    enable_cluster_creator_admin_permissions = bool

    eks_managed_node_groups = map(object({
      ec2 = object({
        ami_type       = string
        instance_types = list(string)
        min_size       = number
        max_size       = number
        desired_size   = number
      })
    }))

    addons = map(any)
    tags   = map(string)
  })
}

############################
# ECR
############################
variable "ecr" {
  description = "Configuration for ECR"
  type = object({
    repositories                           = list(string)
    repository_type                        = string
    repository_force_delete                = bool
    repository_image_scan_on_push          = bool
    manage_registry_scanning_configuration = bool
    registry_scan_type                     = string
    tags                                   = map(string)
  })
}

############################
# RDS
############################
variable "db" {
  description = "Configuration for RDS Instance"
  type = object({
    identifier                          = string
    engine                              = string
    engine_version                      = string
    instance_class                      = string
    allocated_storage                   = string
    storage_type                        = string
    create_db_instance                  = bool
    create_db_parameter_group           = bool
    create_db_option_group              = bool
    iam_database_authentication_enabled = bool
    create_monitoring_role              = bool
    db_name                             = string
    username                            = string
    password                            = string
    port                                = number
    deletion_protection                 = bool
    security_group_tags                 = map(string)
    tags                                = map(string)
  })
}

############################
# Secret Manager
############################
variable "secret-manager" {
  description = "Configuration for Secret manager"
  type = object({
    name        = string
    description = string
  })
}

############################
# ACM
############################
variable "acm" {
  description = "Configuration for ACM certificate"
  type = object({
    domain_name       = string
    validation_method = string
    tags              = map(string)
  })
}