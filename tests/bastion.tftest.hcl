# Runs with no cloud credentials and no network: the provider is mocked, so every run
# block is plan-only. Requires Terraform >= 1.7 (or OpenTofu >= 1.7) for `mock_provider`.
# This is a test-only requirement; the module itself still supports Terraform >= 1.5.
mock_provider "oci" {}

variables {
  compartment_id               = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  name                         = "test-bastion"
  target_subnet_id             = "ocid1.subnet.oc1.phx.aaaaaaaaexamplesubnet"
  client_cidr_block_allow_list = ["203.0.113.0/24"]
}

run "defaults_are_safe" {
  command = plan

  assert {
    condition     = oci_bastion_bastion.this.bastion_type == "STANDARD"
    error_message = "Bastion must be a STANDARD (managed, session-based) bastion."
  }

  # The module must never widen the allow list on the user's behalf.
  assert {
    condition = (
      length(oci_bastion_bastion.this.client_cidr_block_allow_list) == 1 &&
      contains(oci_bastion_bastion.this.client_cidr_block_allow_list, "203.0.113.0/24")
    )
    error_message = "The client CIDR allow list must be passed through exactly as supplied."
  }

  # A default of 10800 (the API maximum) means every session lives for three hours.
  assert {
    condition     = oci_bastion_bastion.this.max_session_ttl_in_seconds == 3600
    error_message = "Default session TTL must be one hour, not the API maximum."
  }
}

# client_cidr_block_allow_list has no default on purpose: forgetting to set it must be a
# hard error, never a silent "reachable from the whole internet". That property is
# structural (absence of a `default`) and so cannot be asserted from here; the empty-list
# and malformed-CIDR cases below cover what a test can actually reach.
run "rejects_empty_allow_list" {
  command = plan

  variables {
    client_cidr_block_allow_list = []
  }

  expect_failures = [var.client_cidr_block_allow_list]
}

run "rejects_malformed_cidr" {
  command = plan

  variables {
    client_cidr_block_allow_list = ["203.0.113.7"]
  }

  expect_failures = [var.client_cidr_block_allow_list]
}

run "accepts_multiple_cidrs" {
  command = plan

  variables {
    client_cidr_block_allow_list = ["203.0.113.0/24", "198.51.100.10/32", "2001:db8::/32"]
  }

  assert {
    condition     = length(oci_bastion_bastion.this.client_cidr_block_allow_list) == 3
    error_message = "All supplied CIDR blocks must reach the bastion resource."
  }
}

run "rejects_open_ipv4_cidr_by_default" {
  command = plan

  variables {
    client_cidr_block_allow_list = ["203.0.113.0/24", "0.0.0.0/0"]
  }

  expect_failures = [oci_bastion_bastion.this]
}

run "rejects_open_ipv6_cidr_by_default" {
  command = plan

  variables {
    client_cidr_block_allow_list = ["::/0"]
  }

  expect_failures = [oci_bastion_bastion.this]
}

# Any address with a /0 prefix covers the whole address space, not just 0.0.0.0/0.
run "rejects_non_canonical_open_cidr_by_default" {
  command = plan

  variables {
    client_cidr_block_allow_list = ["10.0.0.0/0"]
  }

  expect_failures = [oci_bastion_bastion.this]
}

run "accepts_open_cidr_with_explicit_opt_in" {
  command = plan

  variables {
    client_cidr_block_allow_list = ["0.0.0.0/0"]
    allow_public_client_cidrs    = true
  }

  assert {
    condition     = contains(oci_bastion_bastion.this.client_cidr_block_allow_list, "0.0.0.0/0")
    error_message = "With allow_public_client_cidrs = true a /0 entry must be passed through."
  }
}

run "rejects_ttl_below_minimum" {
  command = plan

  variables {
    max_session_ttl_in_seconds = 1799
  }

  expect_failures = [var.max_session_ttl_in_seconds]
}

run "rejects_ttl_above_maximum" {
  command = plan

  variables {
    max_session_ttl_in_seconds = 10801
  }

  expect_failures = [var.max_session_ttl_in_seconds]
}

run "accepts_explicit_ttl_within_range" {
  command = plan

  variables {
    max_session_ttl_in_seconds = 1800
  }

  assert {
    condition     = oci_bastion_bastion.this.max_session_ttl_in_seconds == 1800
    error_message = "An explicit in-range TTL must be honoured."
  }
}

run "tags_are_passed_through" {
  command = plan

  variables {
    freeform_tags = { Environment = "test" }
    defined_tags  = { "Operations.CostCenter" = "42" }
  }

  assert {
    condition     = oci_bastion_bastion.this.freeform_tags["Environment"] == "test"
    error_message = "Freeform tags must reach the bastion resource."
  }

  assert {
    condition     = oci_bastion_bastion.this.defined_tags["Operations.CostCenter"] == "42"
    error_message = "Defined tags must reach the bastion resource."
  }
}
