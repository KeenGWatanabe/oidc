Here's a **minimal, secure Terraform configuration** to create a temporary IAM user with **only the permissions needed to bootstrap GitHub OIDC**:

### `bootstrap-user.tf`
```hcl
# Temporary IAM user for OIDC bootstrap (delete after use)
resource "aws_iam_user" "oidc_bootstrap" {
  name = "github-oidc-bootstrap-user"
}

# Minimum permissions to create OIDC provider
resource "aws_iam_user_policy" "oidc_bootstrap" {
  name = "oidc-bootstrap-policy"
  user = aws_iam_user.oidc_bootstrap.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iam:CreateOpenIDConnectProvider"]
        Resource = "*"
      },
      # Optional: Add if you need to verify the provider
      {
        Effect   = "Allow"
        Action   = ["iam:GetOpenIDConnectProvider"]
        Resource = "*"
      }
    ]
  })
}

# Generate temporary credentials (output for GitHub Secrets)
resource "aws_iam_access_key" "oidc_bootstrap" {
  user = aws_iam_user.oidc_bootstrap.name
}

# Outputs to copy into GitHub Secrets
output "bootstrap_credentials" {
  sensitive = true
  value = {
    access_key_id     = aws_iam_access_key.oidc_bootstrap.id
    secret_access_key = aws_iam_access_key.oidc_bootstrap.secret
  }
  description = "Add these to GitHub Secrets (delete after OIDC setup)"
}
```

### **How to Use This**:
1. **Apply the Terraform**:
   ```bash
   terraform apply -target=aws_iam_user.oidc_bootstrap
   ```
2. **Copy Outputs to GitHub Secrets**:
   - `AWS_ACCESS_KEY_ID` = `bootstrap_credentials.access_key_id`
   - `AWS_SECRET_ACCESS_KEY` = `bootstrap_credentials.secret_access_key`

3. **After OIDC is Created**:
   ```bash
   # Destroy the temporary user
   terraform destroy -target=aws_iam_user.oidc_bootstrap
   ```

### **Key Security Features**:
1. **Minimal Permissions**: Only allows `CreateOpenIDConnectProvider`.
2. **Auto-Expiring**: Credentials become invalid when the user is deleted.
3. **Audit Trail**: The IAM user's activity is logged in CloudTrail.

### **Alternative (For Organizations)**:
If you need to keep the user but restrict usage:
```hcl
resource "aws_iam_user_policy" "deny_after_use" {
  name = "deny-all-after-bootstrap"
  user = aws_iam_user.oidc_bootstrap.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
    }]
  })
}
```

Would you like me to add a time-based expiration (e.g., using AWS STS) for extra security?