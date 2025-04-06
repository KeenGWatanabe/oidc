### For the **OIDC Bootstrap Phase Only** (initial setup)

1. **Temporary AWS Credentials** (only for initial OIDC creation):
   - Go to your GitHub repo: `Settings > Secrets > Actions`
   - Add these **temporary** secrets:
     - `BOOTSTRAP_AWS_ACCESS_KEY_ID`
     - `BOOTSTRAP_AWS_SECRET_ACCESS_KEY`  
     *(Create these in AWS IAM with limited permissions)*

2. **Bootstrap Workflow** (`.github/workflows/bootstrap-oidc.yml`):
```yaml
- name: Apply OIDC Provider
  run: terraform apply -target=aws_iam_openid_connect_provider.github
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.BOOTSTRAP_AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.BOOTSTRAP_AWS_SECRET_ACCESS_KEY }}
```
