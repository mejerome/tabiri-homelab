variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instance access"
  type        = string
  default     = "netbird-key"
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for administrative access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change to your specific IP ranges for better security
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = "CHANGE_ME"
}

variable "domain_name" {
  description = "Domain name for NetBird services"
  type        = string
  default     = "netbird.example.com"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 60
}

variable "volume_encrypted" {
  description = "Enable encryption for root volume"
  type        = bool
  default     = true
}
