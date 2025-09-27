# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.1] - 2025-09-22

### Added
- `Verikloak::Pundit.reset!` helper to restore default configuration, easing test teardown.
- `Verikloak::Pundit::Delegations` shared module consolidating role and permission helper methods.
- `Verikloak::Pundit::ClaimUtils` for consistent claim normalization across entry points.

### Changed
- `UserContext` memoizes role lookups and caches mapped permissions to reduce repeated work inside policies.
- `UserContext` now normalizes inputs via `ClaimUtils` and supports symbolized permission comparison for mixed role map values.
- Configuration duplication derives from a unified `deep_dup`, ensuring hash keys are copied and nested structures remain isolated.
- README documents the new delegations module, configuration reset helper, and deprecation guidance.

## [0.2.0] - 2025-09-21

### Added
- Allow `permission_role_scope = :all_resources` to respect the new
  `permission_resource_clients` whitelist so only approved clients contribute
  to permission checks.
- Document verikloak-bff and verikloak-audience integration patterns,
  including `env_claims_key` examples and role naming guidance.

### Changed
- `UserContext` now snapshots the configuration at initialization to keep
  behavior consistent even if `Verikloak::Pundit.configure` runs mid-request.
- Bump the minimum `verikloak` runtime dependency to `>= 0.1.5` to pick up
  client whitelist support.

## [0.1.1] - 2025-09-20

### Added
- Optional exposure flag for the Rails helper (`expose_helper_method`) so claims can stay hidden from views when not needed.
- Continuous integration job that installs the latest `verikloak` and `verikloak-rails` releases and executes `integration/check.rb` to verify compatibility.
- Detailed operational guidance in README/ERRORS explaining the risks of `permission_role_scope = :all_resources` and helper exposure.

### Changed
- Configuration publishing now duplicates nested structures and freezes them, reducing race conditions when reconfiguring at runtime.
- `integration/check.rb` now exercises realm/resource roles, permission scopes, and helper exposure to catch regressions early.

## [0.1.0] - 2025-09-20

### Added
- Initial public release of `verikloak-pundit`.
- `Verikloak::Pundit::UserContext` for working with Keycloak JWT claims.
- Rails controller helpers and generator for installing the initializer and base `ApplicationPolicy`.
- Role mapping configuration (`role_map`, `realm_roles_path`, `resource_roles_path`, `permission_role_scope`).
