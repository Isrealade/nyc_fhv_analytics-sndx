module "vpc" {
  source  = "Isrealade/vpc/aws"
  version = "2.1.0"

  name                 = "css-vpc"
  cidr                 = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  private_ip_map       = false

  public_subnet_count  = 3
  private_subnet_count = 3

  enable_nat     = true
  single_nat     = true

  create_db_subnet  = true
  subnet_group_name = "css-db_subnet_group"

  db_subnet_group_tags = {
    Environment = "production"
    Purpose     = "RDS"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/css-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/css-cluster" = "shared"
  }

  ingress = ["https", "kube", "postgresql"]

  tags = {
    Environment = "production"
    Project     = "css-app"
  }
}