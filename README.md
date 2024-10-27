# wizardai-terraform-aws-s3-bucket
Terraform module for creating and managing AWS S3 buckets at Wizard AI

## Overview
This Terraform module creates an AWS S3 bucket with encryption, optional logging and optional lifecycle management. It is designed to comply with organization-level policies and follows Terraform best practices.

## Requirements
- **Terraform 1.6+**
- **AWS Provider 5.x+**
- **AWS IAM Role/User** with necessary permissions to create and manage S3 buckets, KMS keys, and apply policies.

## Usage

### Basic Example

```hcl
module "s3_bucket" {
  source                     = "./wizardai_aws_s3_bucket"
  bucket_name                = "myapp"
  environment                = "development"
  versioning_enabled         = false
  logging_enabled            = false
  kms_admin_arn              = "arn:aws:iam::123456789012:role/KMSAdmin"
  kms_user_arn               = "arn:aws:iam::123456789012:role/KMSUser"
}
```

### Advanced Example with Versioning, Logging, and Lifecycle Rules

```hcl
module "s3_bucket" {
  source                     = "./wizardai_aws_s3_bucket"
  bucket_name                = "myapp"
  environment                = "development"
  versioning_enabled         = true
  logging_enabled            = true
  kms_admin_arn              = "arn:aws:iam::123456789012:role/KMSAdmin"
  kms_user_arn               = "arn:aws:iam::123456789012:role/KMSUser"
  noncurrent_version_expiration_days = 60
  lifecycle_rules = [
    {
      id              = "transition-to-glacier"
      status          = "Enabled"
      transition_days = 30
      storage_class   = "GLACIER"
    },
    {
      id              = "expire-old-versions"
      status          = "Enabled"
      transition_days = 90
      storage_class   = "DEEP_ARCHIVE"
    }
  ]
}
```

## Inputs

| Name                              | Description                                                              | Type     | Default   | Required |
|-----------------------------------|--------------------------------------------------------------------------|----------|-----------|----------|
| `bucket_name`                     | Name of the S3 bucket                                                    | `string` | n/a       | Yes      |
| `environment`                     | Deployment environment (must be one of 'development', 'staging', or 'production')          | `string` | n/a       | Yes      |
| `versioning_enabled`              | Enable or disable versioning for the S3 bucket                           | `bool`   | `true`    | No       |
| `logging_enabled`                 | Enable or disable access logging for the S3 bucket                       | `bool`   | `true`   | No       |
| `kms_admin_arn`                   | ARN of the principal with administrative permissions for the KMS key     | `string` | n/a       | Yes      |
| `kms_user_arn`                    | ARN of the principal allowed to use the KMS key for encryption/decryption| `string` | n/a       | Yes      |
| `noncurrent_version_expiration_days` | Number of days after which noncurrent object versions expire           | `number` | `30`      | No       |
| `lifecycle_rules`                 | List of lifecycle rules for managing object transitions and expiration   | `list(object({ id = string, status = string, transition_days = number, storage_class = string }))` | `[]` | No       |

## Outputs

| Name             | Description                                        |
|------------------|----------------------------------------------------|
| `bucket_id`      | ID of the main S3 bucket                                |
| `bucket_arn`     | ARN of the main S3 bucket                               |

## State Management
This module is designed to be used with a remote backend (e.g., S3/DynamoDB). Configure the backend in the root module as follows:

```hcl
terraform {
  backend "s3" {
    bucket         = "wizardai-terraform-state"
    key            = "s3-bucket/${var.environment}/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "wizardai-terraform-lock"
  }
}
```

## Compliance with Requirements
This module complies with the provided requirements as follows:
- **Encryption at Rest**: Implemented using AWS KMS for server-side encryption.
- **Encryption in Transit**: Enforced by denying any requests that do not use HTTPS.
- **Security Defaults**: Ensures private access by default, with public access blocked and ownership enforced.
- **Naming Convention**: Follows the pattern `wizardai-<name>-<environment>`.
- **Deployment Across Environments**: Designed to work across development, staging, and production environments using the `environment` variable.

## Authors
- **Nancy Cai**
