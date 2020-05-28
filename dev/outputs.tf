output "ec2_public_ip" {
  value = module.instances.public_ip
}

output "alb_dns_name" {
  value = module.instances.alb_dns_name
}
