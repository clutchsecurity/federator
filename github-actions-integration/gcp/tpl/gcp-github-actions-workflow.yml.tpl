name: Connect to a GCP role from a GitHub repository

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

permissions:
  contents: read
jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: "Checkout"
        uses: actions/checkout@v3

      - name: Authenticate with Google Cloud
        uses: google-github-actions/auth@v1
        with:
          workload_identity_provider: $${{ secrets.${workload_identity_provider_secret_name} }}
          service_account: $${{ secrets.${service_account_email_secret_name} }}
          # create_credentials_file: true

      - name: Setup Google Cloud SDK
        uses: google-github-actions/setup-gcloud@v1
        with:
          version: ">= 363.0.0"
          project_id: probable-anchor-420008
          export_default_credentials: true  # Ensure this is set

      - name: List Service Accounts
        run: gcloud iam service-accounts list