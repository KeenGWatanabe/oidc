Here's the optimal structure for managing OIDC bootstrap and regular workflows across repositories:

### Recommended Repository Structure

1. **`infra-oidc-bootstrap` Repository** (contains OIDC foundation)
```
infra-oidc-bootstrap/
├── .github/
│   └── workflows/
│       └── bootstrap-oidc.yml  # Manual trigger
├── oidc.tf                    # OIDC provider config
├── outputs.tf                 # Exports OIDC ARN
└── backend.tf                 # Remote state config
```

2. **Application Repositories** (each has their own workflows)
```
your-service-repo/
├── .github/
│   └── workflows/
│       └── deploy.yml         # Uses OIDC
├── main.tf                    # Role + resource config
└── backend.tf                # References bootstrap state
```

### Implementation Details

#### 1. Bootstrap Repo (`infra-oidc-bootstrap`)
**oidc.tf**:
```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  client_id_list  = ["sts.amazonaws.com"]
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
```

**bootstrap-oidc.yml**:
```yaml
name: Bootstrap OIDC
on: workflow_dispatch
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      
      - name: Terraform Init
        run: terraform init
        
      - name: Apply OIDC Provider
        run: terraform apply -auto-approve -target=aws_iam_openid_connect_provider.github
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.BOOTSTRAP_AWS_ACCESS_KEY }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.BOOTSTRAP_AWS_SECRET }}
```

#### 2. Application Repo (`your-service-repo`)
**main.tf**:
```hcl
data "terraform_remote_state" "oidc" {
  backend = "s3"
  config = {
    bucket = "your-tf-state-bucket"
    key    = "infra-oidc-bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_iam_role" "deploy_role" {
  name = "github-actions-${var.repo_name}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.terraform_remote_state.oidc.outputs.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { 
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" 
        }
        StringLike = { 
          "token.actions.githubusercontent.com:sub" = "repo:your-org/${var.repo_name}:*" 
        }
      }
    }]
  })
}
```

**deploy.yml**:
```yaml
name: Deploy Service
on: [push]
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-${{
            github.event.repository.name }}
          aws-region: us-east-1
          
      - run: terraform apply -auto-approve
```

### Key Benefits

1. **Separation of Concerns**:
   - Bootstrap repo manages account-level OIDC provider
   - Application repos manage their own roles/resources

2. **Security**:
   - Bootstrap credentials used only once
   - Each repo has isolated IAM roles

3. **Scalability**:
   - Add new repos without modifying OIDC provider
   - Update OIDC config in one place

4. **State Isolation**:
   - Bootstrap state contains only OIDC provider
   - Application states remain independent

### Migration Steps

1. First create the bootstrap repo and apply OIDC provider
2. Then in each application repo:
   ```bash
   terraform import aws_iam_openid_connect_provider.github \
     arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
   ```
3. Update application repos to reference remote state

Would you like me to provide the exact Terraform commands for migrating an existing setup to this structure?