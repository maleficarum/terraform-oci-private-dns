locals {
  compute_ip_list = {
    for idc, ip in var.compute_instances_ips : idc => ip
  }
}