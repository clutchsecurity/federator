# GCP to Azure

![](../images/gcp-to-azure-integration.png)

## Demo

[![asciicast](https://asciinema.org/a/Gwr3aeCvOtNvy0AfN3PEzXUye.svg)](https://asciinema.org/a/Gwr3aeCvOtNvy0AfN3PEzXUye)

## Setup

Ensure you are logged into both GCP & Azure systems from your CLI before executing below terraform commands.

### Verify GCP

```
gcloud auth login
gcloud auth application-default login
```

List projects and choose one.

```
gcloud projects list
gcloud config set project <PROJECT_NAME>
```

```
gcloud config list
```

### Verify Azure

```
az account show
```

### Integration

Connect to Azure systems from GCP Cloud. In this example, we will use GCP VM to connect with Azure resources.

```
export GCP_PROJECT_NAME=$(gcloud config list --format="value(core.project)")
terraform init
terraform plan -var gcp_project_name=$GCP_PROJECT_NAME
terraform apply -var gcp_project_name=$GCP_PROJECT_NAME
```

Post `terraform apply`, copy the ssh command from the output and login to the GCP VM.

1. Some pre-requisities will be installed
2. Connectivity to the Azure systems will be established
3. Test it by running the command shown.

#### NOTE

It's observed sometimes, GCP VMs aren't executing the scripts in `/etc/profile.d/` on first ssh login. If that happens with you, there are two ways to fix it.

1. Exit the shell and run the `gcloud ssh` command again.
2. Manually, run the script that will configure the shell to connect with Azure services - `bash /etc/profile.d/set_env_vars.sh`

### Destroy resources

```
terraform destroy -var gcp_project_name=$GCP_PROJECT_NAME
```
