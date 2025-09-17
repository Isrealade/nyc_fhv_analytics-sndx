module "vpc" {
  source  = "Isrealade/vpc/aws"
  version = "1.1.0"
  name    = "css-vpc"
  cidr    = "10.0.0.0/16"

  public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  private_ip_map = false

  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  ingress = []

  public_subnet_tags = {
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/css-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/css-cluster" = "shared"
  }

  tags = {
    Environment = "production"
    Project     = "css-app"
  }
}

module "eks" {
  source     = "terraform-aws-modules/eks/aws"
  version    = "~> 21.0"
  depends_on = [module.vpc]

  name                                     = "css-cluster"
  kubernetes_version                       = "1.33"
  endpoint_public_access                   = true
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

    aws-ebs-csi-driver = {
      preserve = false
    },

    coredns = {
      preserve = false
    }

    metrics-server = {
      # addon_version = "latest"
      preserve = false
    },

    kube-state-metrics = {
      # addon_version = "latest"
      preserve = false
    },

    prometheus-node-exporter = {
      # addon_version = "latest"
      preserve = false
    }
  }

  tags = {
    Environment = "production"
    Project     = "css-app"
  }
}

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
        action = {
          type = "expire"
        }
      }
    ]
  })

  manage_registry_scanning_configuration = true
  registry_scan_type                     = "ENHANCED"


  tags = {
    Terraform   = "true"
    Environment = "production"
    Project     = each.value
    Environment = "dev"
  }
}

resource "aws_secretsmanager_secret" "pg" {
  name        = "pg-db-secret"
  description = "PostgreSQL credentials for backend"

  depends_on = [ module.eks ]
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "css.redeploy.online"
  validation_method = "DNS"

  tags = {
    Environment = "production"
    Project     = "css-cert"
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}