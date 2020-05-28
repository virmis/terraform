variable "ENV" {
}

variable "VPC_ID" {
}

module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "${var.ENV}-alb-sg"
  description = "Security group for ${var.ENV} ALB with HTTP ports open"
  vpc_id      = "${var.VPC_ID}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.web_server_sg.this_security_group_id
}
