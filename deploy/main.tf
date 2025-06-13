provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_instance" "netbird" {
  ami                    = "ami-09e6f87a47903347c" # Amazon Linux 2 AMI (us-east-1)
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.netbird.id]
  associate_public_ip_address = true
  key_name                = "syslog" # Replace with your SSH key name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y epel
              yum install -y docker jq 
              service docker start
              usermod -aG docker ec2-user

        EOF

  tags = {
    Name = "netbird-vpn"
    Purpose = "home-lab"
  }
}

# Route53 record for netbird.syslogsolution.us
resource "aws_route53_record" "netbird" {
  zone_id = "Z0712146HMEDR1E8C2FH" # Replace with your Route53 Hosted Zone ID
  name    = "netbird.syslogsolution.us"
  type    = "A"
  ttl     = 300
  records = [aws_instance.netbird.public_ip]
}

