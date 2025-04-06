To manually trigger your GitHub Actions workflow that's configured with `workflow_dispatch`, follow these steps:

### **How to Manually Run the Workflow**

1. **Go to your GitHub repository**  
   Navigate to:  
   `https://github.com/{your-username}/{your-repo}`

2. **Click on the "Actions" tab**  
   This shows all available workflows.

3. **Find your workflow**  
   Look for **"Bootstrap OIDC"** in the left sidebar.

4. **Click "Run workflow"**  
   - A dropdown will appear next to the workflow name.  
   - (If your workflow has inputs, you'll see fields to fill them)  
   - Click the green **"Run workflow"** button.

### **For Workflows with Inputs**
If your workflow has inputs (defined under `workflow_dispatch:`), you'll see fields like:
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
```
→ Fill these in before triggering.

### **Verifying the Run**
- The workflow will appear under **"All workflows"** → **"Bootstrap OIDC"**.
- Click on the run to see live logs.

### **Alternative: Trigger via GitHub CLI**
If you have the [GitHub CLI](https://cli.github.com/) installed:
```bash
gh workflow run "Bootstrap OIDC.yml"
```
(Add `--ref main` if needed)

---

### **Key Notes**
✅ **No code changes needed** – just use the GitHub UI.  
✅ **Runs on the latest commit** by default.  
✅ **Auditable** – appears in the Actions history.  

Need to trigger this from a script or automate it further? Let me know!