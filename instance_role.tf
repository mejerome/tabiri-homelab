
# Create the IAM role and instance profile for the IR-Default role
resource "aws_iam_role" "name" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = var.role_name
  }
}

resource "aws_iam_instance_profile" "name" {
  name = var.role_name
  role = aws_iam_role.name.name
}

# Attach policies to the IAM role
resource "aws_iam_role_policy_attachment" "name" {
  for_each = { for p in var.attach_policies : p => p }

  role       = aws_iam_role.name.name
  policy_arn = each.value
}
