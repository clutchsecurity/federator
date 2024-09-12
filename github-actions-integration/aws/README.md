# AWS OIDC Github Actions Integration

```

cd terraform-provider-idpfingerprint
go build -o terraform-provider-idpfingerprint .
cd ..

# Uncomment `1_idpfingerprint.tf` file
# Uncomment `idpfingerprint` block in `required_providers` in `providers.tf`
terraform init

TF_CLI_CONFIG_FILE=./terraform.rc terraform plan -var-file input.tfvars
TF_CLI_CONFIG_FILE=./terraform.rc terraform apply -var-file input.tfvars
```