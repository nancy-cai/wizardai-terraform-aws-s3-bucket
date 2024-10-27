variable "bucket_name" {
  description = "Name of the S3 bucket. Must only contain lowercase letters, numbers, and hyphens, and be between 3 and 63 characters long."
  type        = string

  validation {
    condition = (
      length(var.bucket_name) <= 40 &&
      regex(var.bucket_name, "^[a-z0-9]+$")
    )
    error_message = "The bucket_name must less than 40 characters long and can only contain lowercase letters and numbers"
  }
}


variable "environment" {
  description = "Deployment environment (must be one of 'development', 'staging', or 'production')"
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of 'development', 'staging', or 'production'."
  }
}


variable "versioning_enabled" {
  description = "Enable or disable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "logging_enabled" {
  description = "Enable or disable logging for the S3 bucket"
  type        = bool
  default     = true
}

variable "kms_admin_arn" {
  description = "ARN of the principal with administrative permissions for the KMS key"
  type        = string
}

variable "kms_user_arn" {
  description = "ARN of the principal allowed to use the KMS key for encryption and decryption"
  type        = string
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which noncurrent object versions expire"
  type        = number
  default     = 30
}

variable "lifecycle_rules" {
  description = "List of maps to define lifecycle rules"
  type = list(object({
    id              = string
    status          = string
    transition_days = number
    storage_class   = string
  }))
  default = []
}
