variable "domain_name" {
  type        = string
  description = "FQDN to handle"
}

# tflint-ignore: terraform_unused_declarations
variable "is_destroying" {
  type        = bool
  default     = false
  description = "True if destroying to use the proper resolver"
}

# tflint-ignore: terraform_unused_declarations
variable "vcn" {
  type        = string
  description = "The VCN OCID"
}

# tflint-ignore: terraform_unused_declarations
variable "network_compartment" {
  type        = string
  description = "The network comparment"
}

variable "compartment_id" {
  type        = string
  description = "Parent compartment where a child compartment to deploy the resources will be created"
}

variable "environment" {
  type        = string
  description = "The target environment"
}

variable "private_subnet" {
  type = object({
    id = string,
    cidr_block : string
  })
  description = "The private subnet OCID"
}

variable "public_subnet" {
  type = object({
    id = string,
    cidr_block : string
  })
  description = "The public subnet OCID"
}

variable "compute_instances_ips" {
  type        = list(string)
  description = "The ips to add to the policy"
}

variable "compute_instances_names" {
  type        = list(string)
  description = "List of VM names"
}