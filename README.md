# Learn Terraform with AWS

This is a beginner Terraform project for AWS.

## Prerequisites
- Terraform installed (v1.0+)
- AWS CLI configured with credentials
- AWS account

## Setup
1. Configure AWS credentials:
   ```bash
   aws configure
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Files
- `main.tf` - Main configuration with provider and resources
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values
- `.gitignore` - Git ignore patterns for Terraform

## Notes
- The example EC2 instance is commented out by default
- Modify `variables.tf` to change default values
- Always run `terraform plan` before `terraform apply`
