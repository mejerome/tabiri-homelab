resource "aws_security_group" "netbird" {
  name        = "netbird-sg"
  description = "Allow WireGuard, SSH, and ICMP for NetBird VPN"
  vpc_id      = aws_vpc.syslog_vpc.id

  tags = {
    Name    = "netbird-sg"
    Purpose = "home-lab"
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
  }

  # Beszel Monitoring
  ingress {
    description = "TCP"
    from_port   = 45876
    to_port     = 45876
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
  }

  # SMTP over TLS
  ingress {
    description = "SMTP over TLS"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "netbird 1"
    from_port   = 10000
    to_port     = 10000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "netbird 2"
    from_port   = 33073
    to_port     = 33073
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "netbird 3"
    from_port   = 33080
    to_port     = 33080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "WireGuard"
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "WireGuard"
    from_port   = 49152
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
