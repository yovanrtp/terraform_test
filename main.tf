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
# The access keys and region are already handled by your Jenkins environment variables.
provider "aws" {
  region = "us-east-1"
}

# ----------------- EC2 Instance Resources -----------------

# 3. Use a Data Source to find the latest Amazon Linux 2023 AMI
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
  instance_type = "t2.micro"

  tags = {
    Name = "Jenkins-Terraform-Lab-EC2"
  }
}


# ----------------- S3 Bucket Module Call -----------------

# 5. Call your reusable S3 module to create a bucket
module "my_lab_bucket" {
  # This tells Terraform to look for the module in the specified local directory
  source = "./modules/s3-bucket"

  # Provide a value for the 'bucket_name' variable defined in the module.
  # IMPORTANT: Change this to a globally unique name!
  bucket_name = "my-unique-jenkins-lab-bucket-98765"

  # (Optional) Provide values for the 'tags' variable
  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform-Jenkins"
  }
}

# ----------------- Outputs -----------------


# 6. (Optional) Output values from both the EC2 instance and the S3 module
output "web_server_public_ip" {
  description = "The public IP of the EC2 instance."
  value       = aws_instance.web_server.public_ip
}

output "lab_bucket_name" {
  description = "The name of the S3 bucket created by the module."
  value       = module.my_lab_bucket.bucket_id
}