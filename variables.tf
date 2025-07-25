# tflint-ignore: terraform_unused_declarations
variable "steering_policy_enabled" {
  type        = bool
  description = "Whether is enabled steering policies."
}

variable "compartment_id" {
  type        = string
  description = "Compartment to deploy the resources"
}

variable "policy" {
  description = "Policy definition"
  type = object({
    name                = string,
    interval_in_seconds = number,
    protocol            = string,
    #http_headers = string,
    http_method  = string,
    http_path    = string,
    http_port    = number,
    http_timeout = number
  })
}

/*variable "http_targets" {
    type = list(string)
    description = "The IPs/HostNames of the backend set"
}*/

variable "domain_name" {
  type        = string
  description = "FQDN to handle"
}

variable "subdomain_name" {
  type        = string
  description = "The subdomain for the policy; or blank"
}

variable "compute_instances_ips" {
  type        = list(string)
  description = "The ips to add to the policy"
}

# tflint-ignore: terraform_unused_declarations
variable "compute_instances_names" {
  type        = list(string)
  description = "List of VM names"
}

variable "environment" {
  type = string
  description = "The target environment"
}

variable "zone_type" {
  type = string
  default = "GLOBAL"
  description = "The zone type (GLOBAL: public, PRIVATE: internal)"
}