You're absolutely right to be cautious about this. Let me clarify the best practice for managing OIDC roles in Terraform:

### **Key Insight: Separation of Concerns**
1. **OIDC Provider Setup** (One-time, account-level):
   - Should **NOT** be in your workflow's `main.tf`
   - Create this separately (manually or via a dedicated Terraform config) because:
     - Only needs to exist once per AWS account
     - Requires elevated permissions you might not want in CI/CD

2. **GitHub Actions Role** (Project-specific):
   - Can live in your workflow's `main.tf`
   - Safe to run repeatedly because:
     - Uses `aws_iam_openid_connect_provider.github.arn` (reference to existing provider)
     - Won't conflict if already exists

---

### **Recommended Structure**

#### 1. **Account-Level Setup** (Run once manually)
`oidc-provider.tf` (apply with admin credentials):
```hcl
# oidc-provider.tf (run once per AWS account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"] 
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
```

#### 2. **Project-Level Setup** (In your workflow's `main.tf`)
```hcl
# main.tf (safe for repeated runs)
resource "aws_iam_role" "github_actions" {
  name = "github-actions-role-${var.project_name}" # Unique per project
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn # References existing provider
      }
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

# Policy attachments (repeatable)
resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" 
}
```

---

### **Why This Works Safely**
- **Idempotent Operations**: 
  - Terraform won't recreate the OIDC provider if it exists (uses `arn` reference)
  - Role names include `project_name` variable to avoid conflicts

- **Permission Isolation**:
  - CI/CD only needs permissions to manage its own role
  - No risk of breaking OIDC provider configuration

- **Clean State**:
  ```bash
  terraform state list
  # Shows only project-specific resources (not account-level OIDC provider)
  ```

---

### **Migration Steps**
1. First, create the OIDC provider manually or via separate Terraform:
   ```bash
   terraform apply -target=aws_iam_openid_connect_provider.github
   ```
2. Then deploy your workflow's Terraform normally.

This approach gives you both safety and reproducibility!

# rger@debian:~/Documents/ntu-cloud-engr/oidc$ `terraform import aws_iam_openid_connect_provider.github arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com`

aws_iam_openid_connect_provider.github: Importing from ID "arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com"...

aws_iam_openid_connect_provider.github: Import prepared!
  Prepared aws_iam_openid_connect_provider for import
aws_iam_openid_connect_provider.github: Refreshing state... [id=arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com]

Import successful!