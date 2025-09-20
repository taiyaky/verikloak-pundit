# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
