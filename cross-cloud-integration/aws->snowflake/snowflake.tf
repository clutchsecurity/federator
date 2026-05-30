# Create a Snowflake service user with workload identity federation configured for AWS.
# The user is created with TYPE = SERVICE and WORKLOAD_IDENTITY pointing to the AWS IAM role.
# Using snowflake_execute because the WORKLOAD_IDENTITY parameter is a newer feature
# that may not be natively supported in the Snowflake Terraform provider's user resource.
resource "snowflake_execute" "wif_service_user" {
  depends_on = [
    aws_iam_outbound_web_identity_federation.this,
    aws_iam_role.ec2_federation_role,
  ]

  execute = <<-SQL
    CREATE USER IF NOT EXISTS ${var.snowflake_wif_username}
      WORKLOAD_IDENTITY = (
        TYPE = AWS
        ARN = '${aws_iam_role.ec2_federation_role.arn}'
        ISSUER = '${aws_iam_outbound_web_identity_federation.this.issuer_identifier}'
      )
      TYPE = SERVICE
      DEFAULT_ROLE = ${var.snowflake_default_role};
  SQL

  revert = "DROP USER IF EXISTS ${var.snowflake_wif_username};"
}

# Grant the default role to the service user so it can be activated on login.
resource "snowflake_execute" "grant_role" {
  depends_on = [snowflake_execute.wif_service_user]

  execute = "GRANT ROLE ${var.snowflake_default_role} TO USER ${var.snowflake_wif_username};"
  revert  = "REVOKE ROLE ${var.snowflake_default_role} FROM USER ${var.snowflake_wif_username};"
}
