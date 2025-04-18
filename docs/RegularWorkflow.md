
### For **Regular Workflows** (after OIDC is setup)

1. **Rotate/Create New GitHub Secrets**:
   - Go to `Settings > Secrets > Actions` in your **application repo** (not bootstrap repo)
   - Add:
     - `AWS_ROLE_ARN` (from Terraform output `github_actions_role_arn`)
     - `AWS_REGION` (e.g., `us-east-1`)

2. **Workflow Authentication** (uses OIDC, no permanent credentials):
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: ${{ secrets.AWS_REGION }}
    # No AWS_ACCESS_KEY_ID needed!
```

### Key Security Practices

1. **Destroy Bootstrap Credentials** after OIDC is working:
   ```bash
   aws iam delete-access-key --user-name terraform-bootstrap --access-key-id AKIA...
   ```
   Then remove from GitHub Secrets.

2. **Least Privilege for Bootstrap User**:
```hcl
# Example minimal policy for bootstrap user
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider"
      ],
      "Resource": "*"
    }
  ]
}
```

3. **Audit Trail**:
   - Check CloudTrail for `AssumeRoleWithWebIdentity` events
   - Monitor GitHub Actions runs

### Visual Workflow

```
[Initial Setup]
GitHub Secrets (Temp) → Bootstrap Workflow → Creates OIDC Provider
                      ↳ (Destroy credentials after)

[Regular Use]
GitHub Secrets (Role ARN) → OIDC Workflow → Assumes IAM Role
```

Would you like me to provide the exact IAM policy for your bootstrap user? This ensures they can only create the OIDC provider and nothing else.