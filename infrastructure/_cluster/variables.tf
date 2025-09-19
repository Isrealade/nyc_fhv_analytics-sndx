############################
# Global
############################
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
}

variable "project" {
  description = "Project or application name"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

############################
# VPC
############################
variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
}

variable "enable_nat" {
  description = "Enable NAT gateways"
  type        = bool
}

variable "single_nat" {
  description = "Use a single NAT gateway across AZs"
  type        = bool
}

variable "create_db_subnet" {
  description = "Create DB subnet group"
  type        = bool
}

variable "db_subnet_group_name" {
  description = "Name for DB subnet group"
  type        = string
}

############################
# EKS
############################
variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "endpoint_public_access" {
  description = "Allow public access to EKS endpoint"
  type        = bool
}

############################
# ECR
############################
variable "repositories" {
  description = "List of ECR repositories to create"
  type        = list(string)
}

############################
# RDS
############################
variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "db_engine" {
  description = "Database engine (e.g., postgres)"
  type        = string
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "db_storage_type" {
  description = "Storage type (gp2/gp3)"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Master username"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
}

############################
# ACM
############################
variable "domain_name" {
  description = "Domain name for ACM certificate"
  type        = string
}