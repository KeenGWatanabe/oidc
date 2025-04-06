# step 1: run tf-backend repo
https://github.com/keengwatanabe/tf-backend

# step 2: place this s3 backend block in main.tf
terraform {
  backend "s3" {
    bucket = "rgers3.tfstate-backend.com"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locks"  # Critical for locking
  }
}

# step 3: put secrets key in github
[secrets keys](accesskeys.md)
[code to create temporary IAM role](bootstrap-tf.md)

