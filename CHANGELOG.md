# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-07-03

### Added
- **`strict_permissions` configuration**: when enabled, `has_permission?` only grants permissions defined as `role_map` values; unmapped role names no longer act as implicit permissions. Recommended together with `permission_role_scope = :all_resources`

### Changed
- Minimum `verikloak` dependency raised to `~> 1.1`, aligned with the verikloak 1.1.0 release (compatibility with verikloak-rails 1.2.0 verified: default user env key and the `verikloak.configure` initializer ordering are unchanged)
- **Helper exposure is evaluated at call time**: `verikloak_claims` is exposed to views through a helper module that consults `expose_helper_method` on each call, so the setting takes effect regardless of initializer ordering. When disabled, views receive `nil` instead of raising `NoMethodError`
- **Reentrant configuration lock**: the internal config `Mutex` was replaced with a `Monitor`, so reading `Verikloak::Pundit.config` inside a `configure` block no longer raises `ThreadError`
- `role_map` values are validated at assignment: Symbols, Strings, and `nil` are accepted; anything else raises `ArgumentError` so misconfiguration surfaces at boot (v1.0.0 silently coerced such values via `to_s`)
- An explicit `nil` value in `role_map` now revokes the role's implicit permission even when `strict_permissions` is off (previously a `nil` mapping was treated as unmapped and the bare role name fell through as a permission)
- Boolean configuration flags (`strict_permissions`, `expose_helper_method`) are coerced to strict `true`/`false` on finalize

### Deprecated
- `RoleMapper.map`: use `RoleMapper.permission_for` instead. `map` now delegates to it, so strict mode and explicit `nil` revocations are honored consistently by every caller

### Security
- Updated locked development/CI dependencies to resolve all known advisories (25 Dependabot alerts): rack 3.2.6, activesupport 8.1.3, concurrent-ruby 1.3.7, faraday 2.14.3, jwt 3.2.0, json 2.20.0. The `pundit ~> 2.3` runtime constraint is unchanged (the `verikloak` constraint bump is listed under Changed)

### Removed
- **Unused `rack` runtime dependency**: the gem only reads the Rack env Hash and uses no Rack APIs (`rack-test` was likewise removed from development dependencies)

### Fixed
- **Per-client `resource_role?` with the default configuration**: the default `resource_roles_path` lambda ignored the requested client, so `resource_role?(client, role)` always inspected the default resource client's roles — granting or denying based on the wrong client. The default path lambda now receives `(config, client)` and resolves the explicitly requested client
- **Path lambdas with optional or variadic parameters**: custom `resource_roles_path` lambdas such as `->(cfg, client = nil) { ... }` (negative arity) never received the requested client and silently fell back to the default resource client. Zero-argument procs are now called as thunks, single-argument procs receive `(config)`, and every other signature receives `(config, client)`
- ERRORS.md no longer claims configuration is not thread-safe (stale since the v1.0.0 thread-safety fix)

### Internal
- Refactoring: unified deep-copy helpers in `Configuration` (removed the `dup_hash`/`dup_string`/`dup_array` wrappers and the redundant `dup` override), simplified `RoleMapper.map` and `UserContext#normalize_to_symbol`
- Test coverage: added specs for `Delegations`, `ClaimUtils`, `Railtie.sync_with_verikloak_rails`, `UserContext.from_env`, the `KEYCLOAK_RESOURCE_CLIENT` ENV fallback, and strict permission mode. Spec files are now linted by RuboCop, and Rails-stubbing specs share a scoped `stub_require` helper instead of mutating `$LOADED_FEATURES`

---

## [1.0.0] - 2026-02-15

### Fixed
- **Thread-safety**: `config_mutex` is now eagerly initialized at load time. The previous `||= Mutex.new` pattern was racy — two threads could create separate Mutex instances, defeating mutual exclusion

### Removed
- **BREAKING**: `Verikloak::Pundit::Policy` and `Verikloak::Pundit::Helpers` deprecated modules have been removed as announced in their deprecation notices. Use `Verikloak::Pundit::Delegations` directly instead

### Changed
- **BREAKING**: Minimum `verikloak` dependency raised to `~> 1.0`
- **v1.0.0 stable release**: Public API is now considered stable under Semantic Versioning

---

## [0.4.0] - 2026-02-15

### Changed
- **BREAKING**: Minimum `verikloak` dependency raised to `>= 0.4.0, < 1.0.0`
- Dev dependency `rspec` pinned to `~> 3.13`, `rubocop-rspec` pinned to `~> 3.9`

### Fixed
- **ClaimUtils.normalize observability**: `rescue StandardError` now captures the exception and emits a `warn` when `$DEBUG` is enabled, improving debuggability of malformed claims

---

## [0.3.0] - 2026-01-01

### Fixed
- **ENV fallback preservation**: `Configuration#dup` now correctly preserves the `nil` state of `resource_client`, allowing ENV fallback to remain dynamic after duplication. Previously, duplicating a config would freeze the resolved ENV value.
- **Non-hash resource_access entries**: `resource_roles_all_clients` now guards against malformed `resource_access` entries that are not hashes, preventing potential `NoMethodError`.

### Changed
- **role_map key normalization**: `role_map` keys are now automatically normalized to symbols when set. This allows users to configure with string keys (e.g., from YAML) while maintaining consistent symbol-based lookup in `RoleMapper`.
- **pundit_user memoization**: `Controller#pundit_user` is now memoized with `@pundit_user ||=` to avoid creating multiple `UserContext` instances per request.

---

## [0.2.4] - 2026-01-01

### Added
- **Environment variable fallback**: `resource_client` now falls back to `ENV['KEYCLOAK_RESOURCE_CLIENT']` when not explicitly configured, enabling environment-based configuration.
- **Auto-sync with verikloak-rails**: When used alongside `verikloak-rails`, `env_claims_key` is automatically synchronized from `Verikloak::Rails.config.user_env_key` if not explicitly set.

### Changed
- **Simplified initializer template**: Generator now produces a minimal initializer with commented examples instead of explicit defaults. Most settings work out of the box.
- **README improvements**: Updated Configuration section with environment variables table, auto-configuration documentation, and removed redundant examples.
- **Consistent Pundit include**: Quick Start examples now use `Pundit::Authorization` consistently.

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
