data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = false

  # Main cloud-init config file
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/user_data.yaml", {
      ssh_authorized_keys       = var.ssh_authorized_keys
      backend_ip                = var.backend_ip
      sni_domain1               = var.sni_domain1
      extra_cloud_config_config = var.extra_cloud_config_config
      listener_ip               = hcloud_primary_ip.primary_ip_1.ip_address
    })
  }
}
