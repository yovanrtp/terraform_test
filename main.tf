# 1. Define the required provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 2. Configure the AWS Provider
# The access keys and region are already handled by your Jenkins environment variables,
# so we just need a basic provider block here.
provider "aws" {
  region = "us-east-1"
}

# 3. Use a Data Source to find the latest Amazon Linux 2023 AMI automatically
# This prevents you from having to hardcode an AMI ID that might expire.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 4. Define the EC2 Instance Resource
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro" # Free-tier eligible and standard for labs

  # Add a tag so you can easily identify it in the AWS Console
  tags = {
    Name = "Jenkins-Terraform-Lab-EC2"
  }
}