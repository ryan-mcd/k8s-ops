# Create a new server running debian
resource "hcloud_server" "proxy" {
  name         = "proxy-hetzner"
  image        = "ubuntu-22.04"
  server_type  = "cpx11"
  datacenter   = "ash-dc1"
  firewall_ids = [hcloud_firewall.proxy_firewall.id]
  ssh_keys     = ["${hcloud_ssh_key.default.id}"]
  user_data    = data.cloudinit_config.this.rendered
  public_net {
    ipv4_enabled = true
    ipv4 = hcloud_primary_ip.primary_ip_1.id
    ipv6_enabled = true
  }
}

### Server creation with one linked primary ip (ipv4)
resource "hcloud_primary_ip" "primary_ip_1" {
name          = "primary_proxy_ip"
datacenter    = "ash-dc1"
type          = "ipv4"
assignee_type = "server"
auto_delete   = false
}
resource "hcloud_firewall" "proxy_firewall" {
  name = "proxy-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = var.allowed_ssh_ips
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_ssh_key" "default" {
  name       = "ssh_key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhRYUuIEXcUuGEWnmkXeZFN890IWSRJrDCy4GHw4uxG"
}