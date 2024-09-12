# output "aws_iam_openid_connect_provider_arn" {
#     value = aws_iam_openid_connect_provider.default.arn
# }

# output "aws_iam_role_arn" {
#   value = aws_iam_role.github_action.arn
# }

# # output "trust_policy" {
# #   value     = local.trust_policy
# #   description = "The IAM role trust policy JSON"
# # }

# output "github_actions_secret_output" {
#   value = github_actions_secret.oidc_role_arn_secret.id
# }

# output "github_repository_details" {
#     value = [
#         github_repository_file.github_actions_workflow.file,
#         github_repository_file.github_actions_workflow.repository
#     ]
#     description = "Github repository details"
# }

output "check_status" {
  value = "Check https://github.com/${var.github_username}/${var.github_repo_name}/actions"
}
