module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier              = "css-db"
  engine                  = "postgres"  
  engine_version          = "17.4"     
  instance_class          = "db.t3.micro"  
  allocated_storage       = 20          
  storage_type            = "gp3"  

  create_db_instance = true 
  create_db_parameter_group = false
  create_db_option_group = false
  vpc_security_group_ids = [ module.vpc.security_group_id ]

  iam_database_authentication_enabled = true
  create_monitoring_role = false

  # DB subnet group
  create_db_subnet_group = false
  db_subnet_group_name = module.vpc.db_subnet_group_name
          

  db_name  = "fhv"
  username = "postgres"
  port     = "5432"

  deletion_protection = false
  

  tags = {
    Environment = "production"
    Project     = "css-app"
  }
}