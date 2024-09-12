#!/bin/bash
cat <<EOF > /etc/profile.d/set_env_vars.sh
#!/bin/bash
echo "Installing some pre-requisites"
sudo snap install google-cloud-cli --classic
echo "Running 'gcloud auth login --cred-file=/home/${admin_user}/gcp.json'"
gcloud auth login --cred-file=/home/${admin_user}/gcp.json
echo "Running 'gcloud config set project ${gcp_project_name}'"
gcloud config set project ${gcp_project_name}
echo "Fetching permissions of associated IAM account"
echo "Running 'gcloud iam service-accounts get-iam-policy ${gcp_service_account_email}'"
gcloud iam service-accounts get-iam-policy ${gcp_service_account_email}
EOF
chmod +x /etc/profile.d/set_env_vars.sh
