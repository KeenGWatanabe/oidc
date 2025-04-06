# Step 1 oidc.tf (run once per AWS account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com" # arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com 
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # from cli 74f3a68f16524f15424927704c9506f55a9316bd
  client_id_list  = ["sts.amazonaws.com"]
}

# outputs.tf
output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

# store your backend state in s3
terraform {
  backend "s3" {
    bucket = "rgers3.tfstate-backend.com" # change name if needed
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locks"  # Critical for locking
  }
}