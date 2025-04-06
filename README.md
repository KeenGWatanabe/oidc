# step 1: run tf-backend repo
https://github.com/keengwatanabe/tf-backend

# step 2: (once only), create temporary user for aws credentials to GitHub
[code to create temporary IAM role](bootstrap-tf.md)
[how](accesskeys.md) step 1 "Temporary AWS Credentials"

# step 3: place this s3 backend block in main.tf
terraform {
  backend "s3" {
    bucket = "rgers3.tfstate-backend.com"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locks"  # Critical for locking
  }
}

# step 4: put secrets key in github
[secrets keys](accesskeys.md) step 2 for "Regular workflow"

