# Step 1 oidc.tf (run once per AWS account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com" # arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com 
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] #74f3a68f16524f15424927704c9506f55a9316bd from cli
  client_id_list  = ["sts.amazonaws.com"]
}

# Step 2 Create IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"
  
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { 
        "Federated": "arn:aws:iam::255945442255:role/github-actions-role" 
        }, # aws_iam_openid_connect_provider.github.arn
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": { 
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" 
        },
        "StringLike": { 
          "token.actions.githubusercontent.com:sub": "repo:KeenGWatanabe/odic:*" 
        }
      }
    }]
  })
}


# Step 3 Assign permissions
# resource "aws_iam_role_policy_attachment" "github_actions" {
#   role       = aws_iam_role.github_actions.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Start broad, then restrict
# }
# Step 3.1 Policy attachements (additional polices added)
# resource "aws_iam_role_policy_attachment" "dynamodb" {
#   role       = aws_iam_role.github_actions.name  
#   policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" 
# }

resource "aws_iam_policy" "github_actions" {
  name = "github-actions-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:*", "dynamodb:*"] # Customize as needed
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
  


# Step4 reference ARN role in GH workflows
output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
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