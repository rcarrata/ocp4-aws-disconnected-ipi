resource "aws_key_pair" "ocp4" {
  key_name   = "ocp4-deploy"
  public_key = var.ssh_key
}

resource "aws_instance" "bastion" {
  ami = var.ec2_ami

  instance_type = var.instance_type

  tags = merge(
    {
      "Name" = "${var.clustername}-bastion"
    },
    var.tags,
  )

  root_block_device {
    volume_size = var.root_volume_size
  }

  subnet_id       = var.az_to_subnet_id[var.availability_zones[0]]
  security_groups = var.bastion_sg_id

  volume_tags = merge(
    {
      "Name" = "${var.clustername}-bastion-vol"
    },
    var.tags,
  )

  # Bastion needs to have public IP 
  associate_public_ip_address = true

  key_name = aws_key_pair.ocp4.key_name

}
