name: Connect to an AWS role from a GitHub repository
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
permissions:
      id-token: write
      contents: read
jobs:
  AssumeRoleAndCallIdentity:
    runs-on: ubuntu-latest
    steps:
      - name: Git clone the repository
        uses: actions/checkout@v3
      - name: configure aws credentials
        uses: aws-actions/configure-aws-credentials@v1.7.0
        with:
          role-to-assume: $${{ secrets.${oidc_role_arn_secret_name} }}
          role-session-name: ${role_session_name}
          aws-region: ${aws_region}
      - name: Sts GetCallerIdentity
        run: |
          aws sts get-caller-identity