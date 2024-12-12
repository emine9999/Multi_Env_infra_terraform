module "networking" {
  source = "../modules/networking"
}

module "eks" {
  source = "../modules/eks"
  
  environment = [var.environment[1]]  # ["staging"]
  private_subnet_ids = slice(module.networking.private_subnet_ids, 1, 3)  # Second VPC's private subnets
  vpc_id = module.networking.vpc_ids[1]  # Second VPC
    public_subnet_ids  = slice(module.networking.public_subnet_ids, 1, 3)

}

module "rds" {
  source = "../modules/rds"
  
  environment           = [var.environment[1]]  # or [2] for prod
  db_subnet_ids        = slice(module.networking.db_subnet_ids, 1, 3)  # Both subnet IDs for Multi-AZ
  vpc_id               = module.networking.vpc_ids[1]  # or [2] for prod
  eks_security_group_id = module.eks.security_group_id[1]
}

module "s3" {
  source = "../modules/s3"
  
  environment = [var.environment[1]]  # ["staging"]
  bucket_name = "my-company-data"     # Will create: my-company-data-staging
}