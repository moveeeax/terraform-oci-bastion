variable "compartment_id" {
  description = "OCID of the compartment in which to create the bastion."
  type        = string
}

variable "name" {
  description = "Name of the bastion (unique within the compartment)."
  type        = string
}

variable "target_subnet_id" {
  description = "OCID of the subnet the bastion routes sessions into."
  type        = string
}

variable "client_cidr_block_allow_list" {
  description = <<-EOT
    List of CIDR blocks allowed to connect to sessions on this bastion. Required and
    deliberately without a default: a bastion is a hole in the network perimeter, so the
    set of source networks that may reach it has to be an explicit decision. Narrow this
    to your office, VPN or CI egress ranges. A /0 entry ("0.0.0.0/0" or "::/0") exposes
    the bastion endpoint to the entire internet and is rejected unless
    allow_public_client_cidrs = true.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.client_cidr_block_allow_list) > 0
    error_message = "At least one client CIDR block must be provided."
  }

  validation {
    condition     = alltrue([for cidr in var.client_cidr_block_allow_list : can(cidrhost(cidr, 0))])
    error_message = "Every entry must be a valid CIDR block, e.g. \"203.0.113.0/24\" (a bare IP address is not accepted; use \"/32\")."
  }
}

variable "allow_public_client_cidrs" {
  description = "Allow /0 entries (\"0.0.0.0/0\", \"::/0\") in client_cidr_block_allow_list. Off by default, so an allow list open to the whole internet fails at plan time instead of being applied by accident."
  type        = bool
  default     = false
}

variable "max_session_ttl_in_seconds" {
  description = "Maximum time-to-live for sessions created on the bastion, in seconds (1800-10800). Defaults to one hour; raise it deliberately, sessions that outlive the work they were opened for are the ones that get abused."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_ttl_in_seconds >= 1800 && var.max_session_ttl_in_seconds <= 10800
    error_message = "max_session_ttl_in_seconds must be between 1800 and 10800."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the bastion."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the bastion, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
