# oidc-provider.tf (run once per AWS account)
resource "aws_iam_openid_connect_provider" "oidc-github" {
  url             = "https://token.actions.githubusercontent.com" # arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com 
  client_id_list  = ["sts.amazonaws.com"] 
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Add this output block to display the OIDC provider ARN
output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc-github.arn
  description = "The ARN of the GitHub OIDC provider"
}