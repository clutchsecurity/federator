resource "aws_iam_openid_connect_provider" "default" {

  # wait to get the fingerprint
  depends_on = [ data.idpfingerprint.default ]

  # provider url
  url = var.openid_connect_url

  # audience
  client_id_list = var.client_id_list

  # thumbprint list for given url
  thumbprint_list = [
    data.idpfingerprint.default.fingerprint,
  ]
}
