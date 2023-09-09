module "pki" {
  source = "git::https://github.com/ryan-mcd/vault-pki.git?ref=e3a40c0e03c9f828ac10ca07b715c47377c0cd92"

  vault_uri                  = "https://hashivault.rmcd.win"
  root_path                  = "pki_root"
  intermediate_path          = "pki_int"
  root_cn                    = data.sops_file.secrets.data["root_cn"]
  organization               = data.sops_file.secrets.data["org"]
  ou                         = data.sops_file.secrets.data["ou"]
  province                   = data.sops_file.secrets.data["province"]
  locality                   = data.sops_file.secrets.data["locality"]
  int_cn                     = data.sops_file.secrets.data["int_cn"]
#   allowed_domains            = [ jsonencode(data.sops_file.secrets.data["allowed_domains"]) ]
#   client_cert_cn             = data.sops_file.secrets.data["client_cert_cn"]
}

resource "vault_pki_secret_backend_sign" "client_cert" {
  depends_on  = [module.pki]
  backend     = module.pki.int_pki_backend_path
  name        = module.pki.int_pki_client_role_name
  csr         = data.sops_file.secrets.data["client_cert_csr"]
  common_name = data.sops_file.secrets.data["client_cert_cn"]
}

resource "local_file" "client_cert_cert" {
  content  = vault_pki_secret_backend_sign.client_cert.certificate
  filename = "${path.module}/client-cert.pem"
}

output client_cert {
    value     = vault_pki_secret_backend_sign.client_cert # module.pki.client_cert
    sensitive = true
}

resource "vault_pki_secret_backend_role" "webserver-certs" {
  backend                            = module.pki.int_pki_backend_path
  name                               = "webserver-certs"
  max_ttl                            = 94608000
  allow_ip_sans                      = true
  key_type                           = "rsa"
  key_bits                           = 2048
  allow_any_name                     = false
  allow_localhost                    = true
  allow_subdomains                   = true
  allow_bare_domains                 = true
  allow_wildcard_certificates        = true
  allowed_domains                    = [ "${data.sops_file.secrets.data["DOMAIN_1"]}", "${data.sops_file.secrets.data["DOMAIN_2"]}", "${data.sops_file.secrets.data["DOMAIN_3"]}", "${data.sops_file.secrets.data["DOMAIN_4"]}", "${data.sops_file.secrets.data["DOMAIN_5"]}"]
}