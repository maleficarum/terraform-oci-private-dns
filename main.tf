resource "oci_identity_compartment" "dns_compartment" {
  compartment_id = var.compartment_id
  description    = "Compartment for DNS resources"
  name           = "dns"
}

resource "oci_dns_view" "private_view" {
  compartment_id = oci_identity_compartment.dns_compartment.id
  display_name   = "private_view_${replace(var.domain_name, ".", "_")}"
  scope          = "PRIVATE"

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }
}

resource "oci_dns_zone" "private_zone" {
  compartment_id = oci_identity_compartment.dns_compartment.id
  name           = var.domain_name
  zone_type      = "PRIMARY"
  scope          = "PRIVATE"
  view_id        = oci_dns_view.private_view.id

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_dns_resolver" "vcn_resolver" {
  compartment_id = oci_identity_compartment.dns_compartment.id
  display_name   = "${var.domain_name}-resolver"
  scope          = "PRIVATE"
  resolver_id    = data.oci_dns_resolvers.vcn_resolvers.resolvers[0].id
  #resolver_id    = length(data.oci_dns_resolvers.vcn_dns_resolvers.resolvers) > 0 ? data.oci_dns_resolvers.vcn_dns_resolvers.resolvers[0].id : data.oci_dns_resolvers.vcn_net_resolvers.resolvers[0].id

  attached_views {
    view_id = oci_dns_view.private_view.id
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }
}

resource "oci_dns_resolver_endpoint" "private_endpoint" {
  resolver_id   = oci_dns_resolver.vcn_resolver.id
  name          = "private_endpoint"
  is_forwarding = true
  is_listening  = false
  subnet_id     = var.private_subnet.id
  scope         = "PRIVATE"
}

# Public Subnet Endpoint
resource "oci_dns_resolver_endpoint" "public_endpoint" {
  resolver_id   = oci_dns_resolver.vcn_resolver.id
  name          = "public_endpoint"
  is_forwarding = false
  is_listening  = true
  subnet_id     = var.public_subnet.id
  scope         = "PRIVATE"
}

#resource "oci_core_dhcp_options" "private_dns" {
#  compartment_id = oci_identity_compartment.dns_compartment.id
#  vcn_id         = var.vcn
#  display_name   = "private_dns_options"

#  options {
#    type        = "DomainNameServer"
#    server_type = "VcnLocalPlusInternet"
#  }

#  options {
#    type                = "SearchDomain"
#    search_domain_names = [var.domain_name]
#  }
#}

resource "oci_dns_rrset" "compute_instances_rrset" {
  for_each = local.compute_ip_list

  zone_name_or_id = oci_dns_zone.private_zone.id
  domain          = "${lower(var.compute_instances_names[each.key])}.${var.domain_name}"
  rtype           = "A"
  compartment_id  = oci_identity_compartment.dns_compartment.id

  items {
    domain = "${lower(var.compute_instances_names[each.key])}.${var.domain_name}"
    rtype  = "A"
    rdata  = var.compute_instances_ips[each.key]
    ttl    = 300
  }
}