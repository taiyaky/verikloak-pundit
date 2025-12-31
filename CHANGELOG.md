# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.3] - 2025-12-31

### Added
- **Database User Integration Guide**: New README section documenting the custom `UserContext` pattern for combining JWT claims with database user models, including controller setup and policy examples.
- **Delegations Module Documentation**: Comprehensive usage guide for `Verikloak::Pundit::Delegations`, covering requirements, custom `UserContext` compatibility, and nil user handling patterns.

### Changed
- Clarified controller setup examples to use `Verikloak::Pundit::Controller` (this gem) instead of `Verikloak::Rails::Controller` (verikloak-rails gem).
- Added explicit notes about method origins (`verikloak_claims` vs `current_user_claims`) for users combining multiple Verikloak gems.
- Enhanced nil user handling documentation with `safe_has_role?` helper pattern for public endpoints.
- Bump minimum `verikloak` dependency from `>= 0.2.0` to `>= 0.3.0` to align with latest upstream releases.
- Update Ruby version to 3.4.8 in development environment.

## [0.2.2] - 2025-09-28

### Changed
- Expanded generator specs to cover pre-existing `application_policy.rb` files and verify directory creation semantics, reinforcing the install generator contract.
- Clarified the dummy generator base `desc` signature to mirror the Rails API and avoid warning noise in tests.
- Stubbed helper and policy spec deprecation warnings so suite output stays clean while still asserting the message payload.

## [0.2.1] - 2025-09-27

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
