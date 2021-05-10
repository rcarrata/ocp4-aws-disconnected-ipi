output "private_ip_address" {
  value = aws_instance.bastion.*.private_ip
}

output "public_ip_address" {
  value = aws_instance.bastion.*.public_ip
}
