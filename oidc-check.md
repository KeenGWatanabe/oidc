Here’s the **AWS CLI command** to check if your GitHub OIDC provider exists, along with how to verify its details:

### **1. Check if OIDC Provider Exists**
```bash
aws iam list-open-id-connect-providers
```
**Expected Output** (if configured):
```json
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
        }
    ]
}
```
If the output is empty, the OIDC provider isn’t set up yet.

---

### **2. Get Full OIDC Provider Details**
If the provider exists, fetch its configuration:
```bash
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
```
**Key Fields to Verify**:
- `Url`: Should match `https://token.actions.githubusercontent.com`
- `ClientIDList`: Must include `sts.amazonaws.com`
- `ThumbprintList`: Should include GitHub’s thumbprint (`6938fd4d98bab03faadb97b34396831e3780aea1`)

---

### **3. Verify IAM Role Trust Policy**
Ensure your IAM role trusts the OIDC provider:
```bash
aws iam get-role --role-name github-actions-role --query 'Role.AssumeRolePolicyDocument'
```
**Check for**:
- `Principal` with the OIDC provider ARN.
- Correct `Condition` for your repo (e.g., `repo:your-org/your-repo:*`).

---

### **Common Fixes if Missing**
1. **Create the OIDC Provider** (if missing):
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
   ```

2. **Update IAM Role Trust Policy** (if incorrect):
   Use the ARN from `list-open-id-connect-providers` in your role’s trust policy.

---

### **Why This Matters**
- GitHub Actions OIDC **won’t work** if the provider isn’t configured in AWS.
- The CLI commands help you **debug** the `Not authorized to perform sts:AssumeRoleWithWebIdentity` error.

Let me know if you need help interpreting the output!