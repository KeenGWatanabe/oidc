# step 1: run tf-backend repo
https://github.com/keengwatanabe/tf-backend

# step 2: (once only), create for aws credentials to GitHub
[code IF A/C able to create temporary IAM role](./docs/bootstrap-tf.md)
[code IF A/C unable to create IAM role](./docs/usingCurrPrivileges.md)
[manual trigger create OIDC workflow](./docs/manualTrigger.md)

[how](./docs/accesskeys.md) step 1 "Temporary AWS Credentials"

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
[secrets keys](./docs/accesskeys.md) step 2 for "Regular workflow"

