# Terraform Secrets Management & Automatic Rotation
# Organization: Apex Cloud Financial Systems (ApexPay)
# Standard Mapping: PCI-DSS v4.0 Requirement 3.6 / 8.6, SOC 2 CC6.1

resource "aws_kms_key" "secrets_kms_key" {
  description             = "KMS CMK for ApexPay Secrets Manager Encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "apexpay/prod/db-credentials"
  description             = "Database access credentials for production payment gateway"
  kms_key_id              = aws_kms_key.secrets_kms_key.arn
  recovery_window_in_days = 30
}

# Automated Secret Rotation Policy (30-day rotation schedule)
resource "aws_secretsmanager_secret_rotation" "db_rotation" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:ApexPay-SecretsRotator-Lambda"

  rotation_rules {
    automatically_after_days = 30
  }
}
