# Step 1 oidc.tf (run once per AWS account)
resource "aws_iam_openid_connect_provider" "oidc-github" {
  url             = "https://token.actions.githubusercontent.com" # arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com 
  client_id_list  = ["sts.amazonaws.com"] 
  thumbprint_list = ["74f3a68f16524f15424927704c9506f55a9316bd"]
}

# Step 2 Create IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-role" # unique per project
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect: "Allow" 
      Principal = {
        Federated = "arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com" #data.aws_iam_openid_connect_provider.github.arn # References existing provider
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:keengwatanabe/m3.1-tf-workflows:*"
        }
      }
    }]
  })
}

# Step 3 Assign permissions
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Start broad, then restrict
}

  
# Step 3.1 Policy attachements (additional polices added)
resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = aws_iam_role.github_actions.name  
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" # aws_iam_policy.terraform_lock_policy.arn
}

# Step4 reference ARN role in GH workflows
output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc-github.arn
  description = "The ARN of the GitHub OIDC provider"
}

# to configure GH secrets
output "github_actions_role_arn" {
  description = "ARN of the IAM role that GitHub Actions will assume"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the IAM role that GitHub Actions will assume"
  value       = aws_iam_role.github_actions.name
}