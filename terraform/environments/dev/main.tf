module "networking" {
  source = "../modules/networking"
}

module "eks" {
  source = "../modules/eks"
  
  environment = [var.environment[0]]  # ["dev"]
  private_subnet_ids = [module.networking.private_subnet_ids[0]]  # First VPC's private subnet
  vpc_id = module.networking.vpc_ids[0]  # First VPC
  public_subnet_ids  = [module.networking.public_subnet_ids[0]]

}

module "rds" {
  source = "../modules/rds"
  
  environment           = [var.environment[0]]  # ["dev"]
  db_subnet_ids        = [module.networking.db_subnet_ids[0]]  # Single subnet ID
  vpc_id               = module.networking.vpc_ids[0]
  eks_security_group_id = module.eks.security_group_id[0]
}

module "s3" {
  source = "../modules/s3"
  
  environment = [var.environment[0]]  # ["dev"]
  bucket_name = "my-company-data"     # Will create: my-company-data-dev
}