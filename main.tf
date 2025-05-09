resource "oci_dns_view" "dns_view" {
  compartment_id = var.compartment_id

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }

  display_name = var.domain_name
  freeform_tags = {
  }
  #scope = <<Optional value not found in discovery>>
}


resource "oci_health_checks_http_monitor" "test_http_monitor" {
  #Required
  compartment_id      = var.compartment_id
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

resource "oci_dns_zone" "dns_zone" {
  compartment_id = var.compartment_id

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/terraform"
  }

  dnssec_state = "DISABLED"

  freeform_tags = {
  }

  name      = var.domain_name
  scope     = "GLOBAL"
  zone_type = "PRIMARY"
}

resource "oci_dns_steering_policy_attachment" "test_steering_policy_attachment" {
  #Required
  domain_name        = "${var.subdomain_name}.${var.domain_name}"
  steering_policy_id = oci_dns_steering_policy.export_mypolicy.id
  zone_id            = oci_dns_zone.dns_zone.id

  #Optional
  display_name = "${var.domain_name}-policy-attachment"
}


resource "oci_dns_steering_policy" "export_mypolicy" {

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

  compartment_id = var.compartment_id

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/ivan@sinformex.com"
    "Oracle-Tags.CreatedOn" = "2025-04-30T19:29:18.333Z"
  }

  display_name = "mypolicy"

  freeform_tags = {
  }

  health_check_monitor_id = oci_health_checks_http_monitor.test_http_monitor.id

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



resource "oci_dns_rrset" "ns_record_set" {
  compartment_id = var.compartment_id
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
  compartment_id = var.compartment_id
  domain         = var.domain_name
  items {
    domain = var.domain_name
    rdata  = "ns1.p201.dns.oraclecloud.net. hostmaster.sinformex.com. 2 3600 600 604800 1800"
    rtype  = "SOA"
    ttl    = "300"
  }
  rtype = "SOA"
  #scope = <<Optional value not found in discovery>>
  #view_id = <<Optional value not found in discovery>>
  zone_name_or_id = oci_dns_zone.dns_zone.id
}



