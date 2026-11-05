# terraform-oci-bastion

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
Bastion, giving secure, time-bound SSH access to private resources without exposing them to
the public internet. Individual sessions are created separately against this bastion.

## Usage

```hcl
module "bastion" {
  source = "github.com/moveeeax/terraform-oci-bastion?ref=v1.0.0"

  compartment_id   = var.compartment_id
  name             = "prod-bastion"
  target_subnet_id = var.private_subnet_id

  client_cidr_block_allow_list = ["203.0.113.0/24"]

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Security defaults

A bastion is a deliberate hole in the network perimeter, so this module errs towards the
narrow option:

- **`client_cidr_block_allow_list` is required and has no default.** There is no safe value
  to guess. Set it to the source networks that legitimately need bastion access — your
  office, VPN or CI egress ranges. `["0.0.0.0/0"]` is accepted, but only as an explicit,
  visible-in-review choice.
- **`max_session_ttl_in_seconds` defaults to `3600`** (one hour) rather than the OCI maximum
  of `10800` (three hours). Sessions that outlive the work they were opened for are the ones
  that get abused. Raise it if your workflows genuinely need longer.
- **`bastion_type` is fixed to `STANDARD`**, the managed, session-brokered bastion — the
  only type OCI offers to customers. It is not exposed as a variable, so it cannot be set
  to something the rest of the module's assumptions do not hold for.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name                           | Description                                                     | Type           | Default           | Required |
|--------------------------------|-----------------------------------------------------------------|----------------|-------------------|:--------:|
| `compartment_id`               | OCID of the compartment in which to create the bastion.         | `string`       | n/a               |   yes    |
| `name`                         | Name of the bastion (unique within the compartment).           | `string`       | n/a               |   yes    |
| `target_subnet_id`             | OCID of the subnet the bastion routes sessions into.           | `string`       | n/a               |   yes    |
| `client_cidr_block_allow_list` | CIDR blocks allowed to connect to sessions. No default — see [Security defaults](#security-defaults). | `list(string)` | n/a |   yes    |
| `max_session_ttl_in_seconds`   | Maximum session TTL in seconds (1800-10800).                   | `number`       | `3600`            |    no    |
| `freeform_tags`                | Free-form tags applied to the bastion.                         | `map(string)`  | `{}`              |    no    |
| `defined_tags`                 | Defined tags applied to the bastion, keyed `namespace.key`.     | `map(string)`  | `{}`              |    no    |

## Outputs

| Name                          | Description                                        |
|-------------------------------|----------------------------------------------------|
| `id`                          | OCID of the bastion.                               |
| `name`                        | Name of the bastion.                               |
| `private_endpoint_ip_address` | Private IP of the bastion endpoint.                |
| `state`                       | Lifecycle state of the bastion.                    |

## Tests

The suite in [`tests/`](tests) mocks the OCI provider, so it runs with no credentials and
makes no API calls:

```sh
terraform init -backend=false
terraform test
```

`mock_provider` requires Terraform (or OpenTofu) >= 1.7. That is a test-only requirement —
consuming the module still only needs >= 1.5.

## License

[MIT](LICENSE)
