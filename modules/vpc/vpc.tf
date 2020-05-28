variable "ENV" {
}

variable "AWS_REGION" {
}

module "main-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-${var.ENV}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.AWS_REGION}a", "${var.AWS_REGION}b"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.100.0/24", "10.0.101.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  tags = {
    Terraform   = "true"
    Environment = var.ENV
  }
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.main-vpc.vpc_id
}

output "private_subnets" {
  description = "List of ID of private subnets"
  value       = module.main-vpc.private_subnets
}

output "public_subnets" {
  description = "List of ID of public subnets"
  value       = module.main-vpc.public_subnets
}
