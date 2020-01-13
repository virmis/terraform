output "ec2_private_ip" {
  value = module.instances.private_ip
}

output "ec2_public_ip" {
  value = module.instances.public_ip
}
