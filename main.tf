locals {
  # Entries with a /0 prefix length, i.e. every IPv4 or every IPv6 address.
  open_client_cidrs = [
    for cidr in var.client_cidr_block_allow_list : cidr
    if can(cidrhost(cidr, 0)) && try(tonumber(split("/", cidr)[1]) == 0, false)
  ]
}

resource "oci_bastion_bastion" "this" {
  compartment_id   = var.compartment_id
  name             = var.name
  bastion_type     = "STANDARD"
  target_subnet_id = var.target_subnet_id

  client_cidr_block_allow_list = var.client_cidr_block_allow_list
  max_session_ttl_in_seconds   = var.max_session_ttl_in_seconds

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  # A /0 entry (0.0.0.0/0 or ::/0) lets any address on the internet reach the
  # bastion endpoint. It is the usual copy-paste value, so it needs an explicit
  # opt-in. This lives in a precondition rather than a variable validation
  # because validations can only reference other variables from Terraform 1.9.
  lifecycle {
    precondition {
      condition     = var.allow_public_client_cidrs || length(local.open_client_cidrs) == 0
      error_message = "client_cidr_block_allow_list contains ${join(", ", local.open_client_cidrs)}, which allows the whole internet to reach the bastion. Narrow it to the networks that need access, or set allow_public_client_cidrs = true to accept this deliberately."
    }
  }
}
