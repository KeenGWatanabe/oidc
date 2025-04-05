Here's the clear, step-by-step approach to structure your Terraform configuration correctly:

### 1. Execution Order and File Structure
```
terraform/
├── 0-tf-backend/          # First apply (contains S3 + DynamoDB)
│   ├── main.tf            # Backend resources
│   └── outputs.tf         # Output backend resource names/ARNs
│
├── 1-oidc-provider/       # One-time apply (per AWS account)
│   ├── main.tf            # 1.GitHub OIDC provider 2.IAM role for GitHub 3.IAM policy attach 4.yaml authenticate
│   └── outputs.tf         
│
└── 2-s3-bucket/           # Regular apply (your actual infrastructure)
    ├── main.tf            # S3 bucket + IAM role for GitHub reference from step 1
    └── backend.tf         # References backend from step 0
```

### 2. What Goes Where

#### 0-tf-backend/main.tf (Run first)
```hcl
resource "aws_s3_bucket" "tf_state" {
  bucket = "my-tf-state-bucket" 
  # ... (versioning, encryption, etc) ...
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  # ... (other attributes) ...
}
```

#### 1-oidc-provider/main.tf (Run once)
```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
```

#### 2-s3-bucket/main.tf (Regular usage)
```hcl
# Reference existing OIDC provider
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Create GitHub Actions role
resource "aws_iam_role" "github_actions" {
  name = "github-actions-${var.project_name}"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:your-org/your-repo:*"
        }
      }
    }]
  })
}

# Your actual S3 bucket
resource "aws_s3_bucket" "main" {
  bucket = "my-app-bucket"
  # ...
}
```

### 3. How to Apply

1. **First, deploy the backend**:
   ```bash
   cd 0-tf-backend
   terraform init
   terraform apply  # Creates S3 + DynamoDB
   ```

2. **Then, set up OIDC** (one time):
   ```bash
   cd ../1-oidc-provider
   terraform init -backend-config=../0-tf-backend/backend.tf
   terraform apply
   ```

3. **Finally, regular infrastructure**:
   ```bash
   cd ../2-s3-bucket
   terraform init -backend-config=../0-tf-backend/backend.tf
   terraform apply
   ```

### 4. Key Architecture Notes

1. **No circular dependencies** - Each layer builds on the previous one
2. **Safe to rerun** - OIDC provider won't recreate if exists
3. **Clean separation** - Backend config never mixes with application resources
4. **GitHub Actions workflow** only needs to interact with the `2-s3-bucket` layer

### 5. GitHub Workflow Example
```yaml
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-myproject
          aws-region: us-east-1
      - run: terraform -chdir=2-s3-bucket apply
```

This structure gives you a clean, maintainable setup where each component has a clear purpose and lifecycle.