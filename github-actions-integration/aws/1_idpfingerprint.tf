# provider "idpfingerprint" {

# }

data "idpfingerprint" "default" {
  idp_url = "${var.openid_connect_url}/.well-known/openid-configuration"
}

# output "idp_fingerprint" {
#   value = data.idpfingerprint.default
# }
