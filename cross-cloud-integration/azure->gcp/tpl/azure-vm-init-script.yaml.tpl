#cloud-config
write_files:
  - path: /etc/profile.d/set_env_vars.sh
    content: |
      echo "Installing some pre-requisites"
      sudo snap install google-cloud-cli --classic
      echo "Running 'gcloud auth login --cred-file=/home/${admin_username}/gcp.json'"
      gcloud auth login --cred-file=/home/${admin_username}/gcp.json
      echo "Running 'gcloud config set project ${gcp_project_name}'"
      gcloud config set project ${gcp_project_name}
      echo "Fetching permissions of associated IAM account"
      echo "Running 'gcloud iam service-accounts get-iam-policy $(gcloud auth list --format="value(account)")'"
      gcloud iam service-accounts get-iam-policy $(gcloud auth list --format="value(account)")
