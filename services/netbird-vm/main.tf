provider "aws" {
  region  = var.aws_region
  profile = "default"
}

resource "aws_instance" "netbird" {
  ami                         = "ami-09e6f87a47903347c" # Amazon Linux 2 AMI (us-east-1)
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.netbird.id]
  associate_public_ip_address = true
  key_name                    = var.ssh_key_name

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
    encrypted   = var.volume_encrypted
    tags = {
      Name = "netbird-root-volume"
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y epel
              yum install -y docker jq 
              service docker start
              usermod -aG docker ec2-user
              # Enable automatic security updates
              yum install -y yum-cron
              sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf
              systemctl enable yum-cron
              systemctl start yum-cron
        EOF

  tags = {
    Name    = "netbird-vpn"
    Purpose = "home-lab"
  }
}

# Route53 record for netbird domain
resource "aws_route53_record" "netbird" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_instance.netbird.public_ip]
}
