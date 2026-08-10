data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

locals {
  az_list = ["a", "b", "c"]
  masters = { for i in range(1, 4) : "k8s-master-${i}" => local.az_list[(i - 1) % 3] }
  workers = { for i in range(1, 3) : "k8s-worker-${i}" => local.az_list[(i - 1) % 3] }
}

resource "aws_instance" "master" {
  for_each                = local.masters
  ami                      = data.aws_ami.ubuntu.id
  instance_type            = var.instance_type_k8s
  subnet_id                = aws_subnet.public[each.value].id
  key_name                 = data.aws_key_pair.this.key_name
  vpc_security_group_ids   = [aws_security_group.k8s.id]
  iam_instance_profile     = aws_iam_instance_profile.node_profile.name
  source_dest_check        = false
  root_block_device {
    volume_size = 30
  }
  tags = { Name = each.key }
}

resource "aws_instance" "worker" {
  for_each                = local.workers
  ami                      = data.aws_ami.ubuntu.id
  instance_type            = var.instance_type_k8s
  subnet_id                = aws_subnet.public[each.value].id
  key_name                 = data.aws_key_pair.this.key_name
  vpc_security_group_ids   = [aws_security_group.k8s.id]
  iam_instance_profile     = aws_iam_instance_profile.node_profile.name
  source_dest_check        = false
  root_block_device {
    volume_size = 30
  }
  tags = { Name = each.key }
}

resource "aws_instance" "gitlab" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = "m7i-flex.large"
  subnet_id                = aws_subnet.public["a"].id
  key_name                 = data.aws_key_pair.this.key_name
  vpc_security_group_ids   = [aws_security_group.gitlab_harbor.id]
  root_block_device {
    volume_size = 50
  }
  tags = { Name = "gitlab-vm" }
}

resource "aws_instance" "harbor" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = "c7i-flex.large"
  subnet_id                = aws_subnet.public["b"].id
  key_name                 = data.aws_key_pair.this.key_name
  vpc_security_group_ids   = [aws_security_group.gitlab_harbor.id]
  root_block_device {
    volume_size = 50
  }
  tags = { Name = "harbor-vm" }
}

resource "aws_eip" "gitlab" {
  instance = aws_instance.gitlab.id
  domain   = "vpc"
}

resource "aws_eip" "harbor" {
  instance = aws_instance.harbor.id
  domain   = "vpc"
}

output "gitlab_eip" { value = aws_eip.gitlab.public_ip }
output "harbor_eip"  { value = aws_eip.harbor.public_ip }
