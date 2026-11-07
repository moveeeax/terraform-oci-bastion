# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [2.0.0] - 2026-11-07

### Added

- `allow_public_client_cidrs` input (default `false`) that opts in to `/0`
  entries in `client_cidr_block_allow_list`.

### Changed

- Breaking: `client_cidr_block_allow_list` entries with a `/0` prefix
  (`0.0.0.0/0`, `::/0`) now fail at plan time unless
  `allow_public_client_cidrs = true`. Configurations that pass such an entry
  must either narrow the list or set the flag.

[Unreleased]: https://github.com/moveeeax/terraform-oci-bastion/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/moveeeax/terraform-oci-bastion/compare/v1.1.0...v2.0.0
