# 1. Define the required provider and configure the S3 backend
terraform {
  # This block tells Terraform to store its state file in S3
  backend "s3" {
    # --- UPDATE THESE VALUES ---
    # The name of the S3 bucket you created for storing state.
    bucket         = "my-jenkins-lab-terraform-state-bucket-98765"
    
    # The path and name for the state file in the S3 bucket.
    key            = "prod/jenkins-lab/terraform.tfstate"
    
    # The AWS region where your S3 bucket and DynamoDB table exist.
    region         = "us-east-1"
    
    # The name of the DynamoDB table you created for state locking.
    dynamodb_table = "my-jenkins-lab-terraform-state-lock"
    # --- END OF VALUES TO UPDATE ---
  }

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

# 4. Define the set of EC2 instances to create
locals {
  ec2_instances = {
    web = {
      instance_type = "t2.micro"
      role          = "web-server"
    }
    app = {
      instance_type = "t2.micro"
      role          = "app-server"
    }
    cache = {
      instance_type = "t2.micro"
      role          = "cache-server"
    }
  }
}

# 5. Create one EC2 instance per entry in the map using for_each
resource "aws_instance" "web_server" {
  for_each = local.ec2_instances

  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type

  tags = {
    Name = "Jenkins-Terraform-Lab-${each.key}"
    Role = each.value.role
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
output "web_server_public_ips" {
  description = "Public IPs of all EC2 instances, keyed by instance name."
  value       = { for k, v in aws_instance.web_server : k => v.public_ip }
}

output "lab_bucket_name" {
  description = "The name of the S3 bucket created by the module."
  value       = module.my_lab_bucket.bucket_id
}