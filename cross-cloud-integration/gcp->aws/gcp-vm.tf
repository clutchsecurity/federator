# Resource to generate a private SSH key using the TLS provider
resource "tls_private_key" "example_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a file to store the generated private SSH key
resource "local_file" "private_key_file" {
  depends_on      = [tls_private_key.example_ssh_key]
  content         = tls_private_key.example_ssh_key.private_key_pem
  filename        = "${path.module}/demo_instance_ssh_key.pem"
  file_permission = "0400"
}

# Create a file to store the public SSH key
resource "local_file" "public_key_file" {
  depends_on      = [tls_private_key.example_ssh_key]
  content         = tls_private_key.example_ssh_key.public_key_pem
  filename        = "${path.module}/demo_instance_ssh_key.pem.pub"
  file_permission = "0400"
}

# Deploy a Google Compute Instance with a configured machine type and zone
resource "google_compute_instance" "demo_instance" {
  depends_on   = [random_string.random_suffix]
  name         = "${var.prefix}-demo-instance-${random_string.random_suffix.result}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  # Define the boot disk image for the instance
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  # Setup the network interface and external access
  network_interface {
    network = "default"
    access_config {}
  }

  # Configure the service account and scopes for the instance
  service_account {
    email  = google_service_account.demo.email
    scopes = ["cloud-platform"]
  }

  # Startup script to configure AWS CLI and assume an AWS role via the federated token
  metadata_startup_script = templatefile("${path.module}/tpl/gcp-metadata-startup-script.sh.tpl", {
    aws_iam_role_arn = aws_iam_role.demo_role.arn
  })

  # Attach the public SSH key to the instance for the specified admin user
  metadata = {
    ssh-keys = "${var.gcp_vm_admin_user}:${tls_private_key.example_ssh_key.public_key_openssh}"
  }
}
