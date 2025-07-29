data "oci_dns_resolvers" "vcn_resolvers" {
  compartment_id = var.is_destroying ? oci_identity_compartment.dns_compartment.id : var.network_compartment
  scope          = "PRIVATE"
}

# tflint-ignore: terraform_unused_declarations
data "oci_core_vcn" "target_vcn" {
  vcn_id = var.vcn
}