locals {
  compute_ip_list = {
    for idc, ip in var.compute_instances_ips : idc => ip
  }

  compartment_id = (
    var.existing_compartment != "" ? 
    var.existing_compartment : 
    (length(oci_identity_compartment.dns_compartment) > 0 ? oci_identity_compartment.dns_compartment[0].id : var.compartment_id)
  )
}