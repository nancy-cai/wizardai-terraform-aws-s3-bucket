data "aws_iam_policy_document" "kms_policy" {
  # Administrative permissions for the KMS key
  statement {
    sid    = "Allow administration of the key"
    effect = "Allow"

    # Grant permission to the KMS admin specified by kms_admin_arn
    principals {
      type        = "AWS"
      identifiers = [var.kms_admin_arn]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = ["*"]
  }

  # Usage permissions for the KMS key
  statement {
    sid    = "Allow use of the key"
    effect = "Allow"

    # Grant permission to the KMS user specified by kms_user_arn
    principals {
      type        = "AWS"
      identifiers = [var.kms_user_arn]
    }

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    effect = "Deny"

    # Deny all S3 actions unless they are over a secure connection (HTTPS)
    actions = ["s3:*"]
    resources = [
      "${aws_s3_bucket.this.arn}",
      "${aws_s3_bucket.this.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
