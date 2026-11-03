resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name = "togglemaster-public-ip"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    repository_url = var.repository_url
    db_host        = aws_db_instance.main.address
    db_name        = var.db_name
    db_user        = var.db_username
    secret_arn     = aws_secretsmanager_secret.db.arn
    aws_region     = var.aws_region
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ec2_root_volume_gb
    delete_on_termination = true
    encrypted             = true
  }

  depends_on = [
    aws_db_instance.main,
    aws_iam_role_policy.secrets
  ]

  tags = {
    Name = "togglemaster-app"
  }
}

resource "aws_eip_association" "app" {
  allocation_id = aws_eip.app.id
  instance_id   = aws_instance.app.id
}
