# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0](https://github.com/ganexcloud/terraform-aws-lightsail/compare/v1.0.0...v2.0.0) (2026-09-03)

### ⚠ BREAKING CHANGES

* default names changed for the key pair, load balancer, load
balancer certificate, database, bucket, certificate, distribution and container
service. Consumers relying on the previous defaults must either pass the family
name explicitly to keep the old value, or accept that Terraform replaces those
resources.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01FfekC98XFYQXNJbrKQgLUu

### Features

* derive a distinct name per resource family and order dependent resources ([0b2579a](https://github.com/ganexcloud/terraform-aws-lightsail/commit/0b2579aa8dc662b1b520792e66e34a076ab03dc1))

## 1.0.0 (2026-09-03)

### Features

* add lightsail module ([5086b15](https://github.com/ganexcloud/terraform-aws-lightsail/commit/5086b150691a307311e6b6874a5b3c93cb9cf99f))
