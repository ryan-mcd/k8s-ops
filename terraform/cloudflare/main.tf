data "http" "terraform_cloud_ips" {
  url = "https://app.terraform.io/api/meta/ip-ranges"
  method = "GET"
}

resource "random_uuid" "terraform_cloud_ips" {
  lifecycle {
    precondition {
      condition     = contains([200], data.http.terraform_cloud_ips.status_code)
      error_message = "Status code invalid"
    }
  }
}

resource "cloudflare_access_group" "tf_cloud" {
  account_id = var.cloudflare_account_id
  name       = "tf_cloud_ips"

  include {
    ip = jsondecode(data.http.terraform_cloud_ips.response_body).api
  }
}

# data "cloudflare_zones" "domain" {
#   filter {
#     name = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
#   }
# }

# resource "cloudflare_zone_settings_override" "cloudflare_settings" {
#   zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
#   settings {
#     ssl                      = "strict"
#     always_use_https         = "on"
#     min_tls_version          = "1.2"
#     opportunistic_encryption = "on"
#     tls_1_3                  = "zrt"
#     automatic_https_rewrites = "on"
#     universal_ssl            = "on"
#     browser_check            = "on"
#     challenge_ttl            = 1800
#     privacy_pass             = "on"
#     security_level           = "medium"
#     brotli                   = "on"
#     minify {
#       css  = "on"
#       js   = "on"
#       html = "on"
#     }
#     rocket_loader       = "on"
#     always_online       = "off"
#     development_mode    = "off"
#     http3               = "on"
#     zero_rtt            = "on"
#     ipv6                = "on"
#     websockets          = "on"
#     opportunistic_onion = "on"
#     pseudo_ipv4         = "off"
#     ip_geolocation      = "on"
#     email_obfuscation   = "on"
#     server_side_exclude = "on"
#     hotlink_protection  = "off"
#     security_header {
#       enabled = false
#     }
#   }
# }

data "http" "ipv4" {
  url = "http://ipv4.icanhazip.com"
}

# resource "cloudflare_record" "ipv4" {
#   name    = "ipv4"
#   zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
#   value   = chomp(data.http.ipv4.response_body)
#   proxied = true
#   type    = "A"
#   ttl     = 1
# }

# resource "cloudflare_record" "root" {
#   name    = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
#   zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
#   value   = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain"]}"
#   proxied = true
#   type    = "CNAME"
#   ttl     = 1
# }
