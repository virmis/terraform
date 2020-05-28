module "main-vpc" {
  source     = "../modules/vpc"
  ENV        = "dev"
  AWS_REGION = var.AWS_REGION
}

module "alb-sg" {
  source = "../modules/security"
  ENV    = "dev"
  VPC_ID     = module.main-vpc.vpc_id
}

module "instances" {
  source          = "../modules/instances"
  ENV             = "dev"
  VPC_ID          = module.main-vpc.vpc_id
  PRIVATE_SUBNETS = module.main-vpc.private_subnets
  PUBLIC_SUBNETS  = module.main-vpc.public_subnets
  SECURITY_GROUPS = module.alb-sg.security_group_id
}
