resource "oci_identity_compartment" "dns_compartment" {
  compartment_id = var.compartment_id
  description    = "Compartment for dns resources"
  name           = "dns"
}

resource "oci_dns_view" "dns_view" {
  compartment_id = oci_identity_compartment.dns_compartment.id

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }

  display_name = var.domain_name
  freeform_tags = {
  }
  scope = var.zone_type
}

resource "oci_dns_zone" "dns_zone" {
  compartment_id = oci_identity_compartment.dns_compartment.id

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }

  dnssec_state = "DISABLED"

  freeform_tags = {
  }

  name      = var.domain_name
  scope     = var.zone_type
  zone_type = "PRIMARY"

  view_id        = oci_dns_view.dns_view.id 
}

resource "oci_dns_rrset" "compute_instances_rrset" {
  for_each = local.compute_ip_list

  zone_name_or_id = oci_dns_zone.dns_zone.id
  domain          = "${var.compute_instances_names[each.key]}.${var.domain_name}"
  rtype           = "A"
  compartment_id  = oci_identity_compartment.dns_compartment.id

  items {
    domain = "${var.compute_instances_names[each.key]}.${var.domain_name}"
    rtype  = "A"
    rdata  = var.compute_instances_ips[each.key]
    ttl    = 300
  }
}

resource "oci_dns_rrset" "ns_record_set" {
  count = var.zone_type == "PRIVATE" ? 0 : 1
  compartment_id = oci_identity_compartment.dns_compartment.id
  domain         = var.domain_name
  items {
    domain = var.domain_name
    rdata  = "ns2.p201.dns.oraclecloud.net."
    rtype  = "NS"
    ttl    = "86400"
  }
  items {
    domain = var.domain_name
    rdata  = "ns3.p201.dns.oraclecloud.net."
    rtype  = "NS"
    ttl    = "86400"
  }
  items {
    domain = var.domain_name
    rdata  = "ns4.p201.dns.oraclecloud.net."
    rtype  = "NS"
    ttl    = "86400"
  }
  items {
    domain = var.domain_name
    rdata  = "ns1.p201.dns.oraclecloud.net."
    rtype  = "NS"
    ttl    = "86400"
  }
  rtype = "NS"
  #scope = <<Optional value not found in discovery>>
  #view_id = <<Optional value not found in discovery>>
  zone_name_or_id = oci_dns_zone.dns_zone.id

}

resource "oci_dns_rrset" "soa_record_set" {
  count = var.zone_type == "PRIVATE" ? 0 : 1
  compartment_id = oci_identity_compartment.dns_compartment.id
  domain         = var.domain_name
  items {
    domain = var.domain_name
    rdata  = "ns1.p201.dns.oraclecloud.net. hostmaster.${var.domain_name}. 2 3600 600 604800 1800" #TODO: Cambiar esto para cada dominio
    rtype  = "SOA"
    ttl    = "300"
  }
  rtype = "SOA"
  #scope = <<Optional value not found in discovery>>
  #view_id = <<Optional value not found in discovery>>
  zone_name_or_id = oci_dns_zone.dns_zone.id
}

resource "oci_health_checks_http_monitor" "http_monitor" {
  count = var.steering_policy_enabled ? 1 : 0
  #Required
  compartment_id      = oci_identity_compartment.dns_compartment.id
  display_name        = "${var.domain_name}-http-monitor"
  interval_in_seconds = var.policy.interval_in_seconds
  protocol            = var.policy.protocol
  targets             = var.compute_instances_ips

  #Optional
  #headers = var.policy.http_headers 
  is_enabled         = true
  method             = var.policy.http_method
  path               = var.policy.http_path
  port               = var.policy.http_port
  timeout_in_seconds = var.policy.http_timeout
}

resource "oci_dns_steering_policy_attachment" "steering_policy_attachment" {
  count = var.steering_policy_enabled ? 1 : 0
  #Required
  domain_name        = "${var.subdomain_name}.${var.domain_name}"
  steering_policy_id = oci_dns_steering_policy.export_mypolicy[count.index].id
  zone_id            = oci_dns_zone.dns_zone.id

  #Optional
  display_name = "${var.domain_name}-policy-attachment"
}

resource "oci_dns_steering_policy" "export_mypolicy" {
  count = var.steering_policy_enabled ? 1 : 0

  dynamic "answers" {
    for_each = local.compute_ip_list
    iterator = ip
    content {
      name  = "${ip.key}-instance"
      pool  = "${ip.key}-pool"
      rdata = ip.value
      rtype = "A"
      #is_disabled = try(tostring(answers.value.is_disabled), "false")
    }
  }
  /*
  answers {
    is_disabled = "false"
    name        = "resource1"
    pool        = "resource1"
    rdata       = "10.0.0.1"
    rtype       = "A"
  }
  answers {
    is_disabled = "false"
    name        = "resource2"
    pool        = "resource2"
    rdata       = "10.0.0.2"
    rtype       = "A"
  }*/

  compartment_id = oci_identity_compartment.dns_compartment.id

  defined_tags = {
    "Oracle-Tags.CreatedBy"   = "default/terraform-cae",
    "Oracle-Tags.Environment" = var.environment
  }

  display_name = "steering-policy"

  freeform_tags = {
  }

  health_check_monitor_id = oci_health_checks_http_monitor.http_monitor[count.index].id

  rules {
    default_answer_data {
      answer_condition = "answer.isDisabled != true"
      should_keep      = "true"
      #value = <<Optional value not found in discovery>>
    }
    #default_count = <<Optional value not found in discovery>>
    description = "Removes disabled answers."
    rule_type   = "FILTER"
  }

  rules {
    #default_answer_data = <<Optional value not found in discovery>>
    #default_count = <<Optional value not found in discovery>>
    description = "Removes unhealthy answers."
    rule_type   = "HEALTH"
  }
  rules {

    dynamic "default_answer_data" {
      for_each = local.compute_ip_list
      iterator = ip
      content {
        answer_condition = "answer.pool == '${ip.key}-pool'"
        value            = ip.key
      }
    }

    /*
    default_answer_data {
      answer_condition = "answer.pool == 'resource1'"
      #should_keep = <<Optional value not found in discovery>>
      value = "0"
    }
    default_answer_data {
      answer_condition = "answer.pool == 'resource2'"
      #should_keep = <<Optional value not found in discovery>>
      value = "1"
    }*/
    #default_count = <<Optional value not found in discovery>>
    #description = <<Optional value not found in discovery>>
    rule_type = "PRIORITY"
  }
  rules {
    #default_answer_data = <<Optional value not found in discovery>>
    default_count = "1"
    #description = <<Optional value not found in discovery>>
    rule_type = "LIMIT"
  }
  template = "FAILOVER"
  ttl      = "30"
}
