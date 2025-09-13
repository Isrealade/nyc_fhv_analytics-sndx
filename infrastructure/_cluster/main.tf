module "vpc" {
  source  = "Isrealade/vpc/aws"
  version = "1.1.0"

  name = "css-vpc"
  cidr = "10.0.0.0/16"

  public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  private_ip_map = false

  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  ingress = []

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/css-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
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

  name               = "css-cluster"
  kubernetes_version = "1.33"

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  upgrade_policy = {
    support_type = "STANDARD"
  }

  create_cloudwatch_log_group = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)

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
      # addon_version = "latest" # or pin a specific version
      preserve = false # keeps the addon if the cluster is deleted
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
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.0.1"

  for_each = toset(var.repositories)

  repository_name         = each.value
  repository_force_delete = true

  repository_read_write_access_arns = [module.eks.cluster_iam_role_arn]
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

  # Registry Scanning Configuration
  manage_registry_scanning_configuration = true
  registry_scan_type                     = "ENHANCED"
  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter = [
        {
          filter      = "example1"
          filter_type = "WILDCARD"
        },
        { filter      = "example2"
          filter_type = "WILDCARD"
        }
      ]
      }, {
      scan_frequency = "CONTINUOUS_SCAN"
      filter = [
        {
          filter      = "example"
          filter_type = "WILDCARD"
        }
      ]
    }
  ]


  tags = {
    Terraform   = "true"
    Environment = "production"
    Project     = each.value
    Environment = "dev"
  }
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