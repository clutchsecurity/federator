# Generate a private SSH key using the TLS provider
resource "tls_private_key" "example_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
  # RSA algorithm is used for key generation with a length of 2048 bits for good security and performance balance
}

# Store the generated private SSH key in a local file
resource "local_file" "private_key_file" {
  depends_on      = [tls_private_key.example_ssh_key]
  content         = tls_private_key.example_ssh_key.private_key_pem
  filename        = "${path.module}/demo_instance_ssh_key.pem"
  file_permission = "0400" # Permissions set to read-only for the file owner for security
}

# Store the public SSH key in a local file
resource "local_file" "public_key_file" {
  depends_on      = [tls_private_key.example_ssh_key]
  content         = tls_private_key.example_ssh_key.public_key_pem
  filename        = "${path.module}/demo_instance_ssh_key.pem.pub"
  file_permission = "0400" # Permissions set to read-only for the file owner for security
}

# Create a Google Compute Instance with dependencies on Azure resources for demonstration purposes
resource "google_compute_instance" "demo_instance" {
  depends_on = [
    azuread_application.demo,
    azurerm_role_assignment.demo,
    azuread_app_role_assignment.demo,
    random_string.random_suffix,
    google_service_account.demo,
    tls_private_key.example_ssh_key,
    data.azurerm_client_config.current,
  ]
  name         = "${var.prefix}-demo-instance-${random_string.random_suffix.result}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  # Define the boot disk using a Debian 10 image
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  # Set up network interface with default network and allow external access
  network_interface {
    network = "default"
    access_config {}
  }

  # Assign a service account to the instance with permissions scoped to the entire cloud platform
  service_account {
    email  = google_service_account.demo.email
    scopes = ["cloud-platform"]
  }

  # Metadata to attach the public SSH key to the instance for SSH access
  metadata = {
    ssh-keys = "${var.gcp_vm_admin_user}:${tls_private_key.example_ssh_key.public_key_openssh}"
  }
  
  # Startup script to install required tools, authenticate with Azure, and perform an API request
  metadata_startup_script = <<-EOF
    #! /bin/bash
    # Setup environment by installing Azure CLI and jq
    sudo tee /etc/profile.d/set_env_vars.sh << 'EOT'
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
      sudo apt -y install jq
      # Fetch token from GCP metadata service and use it to authenticate against Azure
      gcp_token=$(curl -H "Metadata-Flavor: Google" 'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity?audience=${var.audience}')
      output=$(curl -X GET 'https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/v2.0/token' --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'client_id=${azuread_application.demo.client_id}' --data-urlencode 'scope=https://graph.microsoft.com/.default' --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' --data-urlencode "client_assertion=$gcp_token" --data-urlencode 'grant_type=client_credentials')
      azure_access_token=$(echo $output | jq -r '.access_token')
      # Prepare a command to query Azure Service Principals using the Azure CLI
      command_to_run=$(echo "az rest --method GET --uri \"https://graph.microsoft.com/v1.0/servicePrincipals\" --skip-authorization-header --headers \"Authorization=Bearer \$azure_access_token\"")
      echo $command_to_run
    EOT
  EOF
}
