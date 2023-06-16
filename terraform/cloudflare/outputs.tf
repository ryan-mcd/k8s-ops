output "terraform_cloud_ips" {
    value = jsondecode(data.http.terraform_cloud_ips.response_body).api
}

output "ip" {
    value = data.http.ipv4.response_body
}