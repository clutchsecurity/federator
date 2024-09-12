name: Run Azure Login with OIDC
on: [push]

permissions:
  id-token: write
  contents: read
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: 'Az CLI login'
        uses: azure/login@v1
        with:
          client-id: $${{ secrets.${client_id_secret_name} }}
          tenant-id: $${{ secrets.${tenant_id_secret_name} }}
          subscription-id: $${{ secrets.${subscription_id_secret_name} }}

      - name: 'Run az commands'
        run: |
          az account show
          az group list