# verikloak-pundit

[![CI](https://github.com/taiyaky/verikloak-pundit/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/taiyaky/verikloak-pundit/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/verikloak-pundit)](https://rubygems.org/gems/verikloak-pundit)
![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.1-blue)
[![Downloads](https://img.shields.io/gem/dt/verikloak-pundit)](https://rubygems.org/gems/verikloak-pundit)

Pundit integration for the **Verikloak** family. This gem maps **Keycloak roles** from JWT claims (e.g., `realm_access.roles`, `resource_access[client].roles`) into a convenient **UserContext** that Pundit policies can consume.

- Requires [`verikloak`](https://rubygems.org/gems/verikloak) at runtime and pairs well with [`verikloak-rails`](https://rubygems.org/gems/verikloak-rails) for Rails integrations.
- Provides a `pundit_user` hook so policies can use `user.has_role?(:admin)` etc.
- Keeps role mapping **configurable** (project-specific mappings differ).

## Features

- **UserContext**: lightweight wrapper around JWT claims
- **Delegations**: `has_role?`, `in_group?`, `resource_role?(client, role)` helpers for controllers and policies
- **RoleMapper**: optional map from Keycloak roles → domain permissions
- **Controller integration**: `pundit_user` provider for Rails controllers
- **Generator**: `rails g verikloak:pundit:install` creates initializer + policy template (with `has_permission?` support for realm roles plus the configured resource scope)

## Installation

```bash
bundle add verikloak-pundit
```

If you're on Rails:

```bash
rails g verikloak:pundit:install
```

This generates:

- `config/initializers/verikloak_pundit.rb`
- `app/policies/application_policy.rb` (template if missing; optional)

For error-handling guidance, see [ERRORS.md](ERRORS.md).

## Quick Start (Rails)

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include Pundit
  include Verikloak::Pundit::Controller  # provides pundit_user

  # If you're also using verikloak-rails:
  # before_action :authenticate_user!
end
```

Your policy can then do:

```ruby
class NotePolicy < ApplicationPolicy
  def update?
    user.has_role?(:admin) || user.resource_role?(:'rails-api', :editor)
  end
end
```

Where `user` is the **UserContext** provided by `pundit_user`.

## Configuration

```ruby
# config/initializers/verikloak_pundit.rb
Verikloak::Pundit.configure do |c|
  c.resource_client = "rails-api"   # default client for resource roles
  c.role_map = {                    # optional role → permission mapping
    admin:  :manage_all,
    editor: :write_notes,
    reader: :read_notes
  }
  # Where to find claims in Rack env (when using verikloak/verikloak-rails)
  c.env_claims_key = "verikloak.user"

  # How to traverse JWT for roles
  c.realm_roles_path    = %w[realm_access roles]                      # => claims["realm_access"]["roles"]
  # Lambdas in the path may accept (cfg) or (cfg, client)
  # where `client` is the argument passed to `user.resource_roles(client)`
  c.resource_roles_path = ["resource_access", ->(cfg){ cfg.resource_client }, "roles"]

  # Permission mapping scope for `user.has_permission?`:
  #   :default_resource => realm roles + default client roles (recommended)
  #   :all_resources    => realm roles + roles from all clients in resource_access
  #                         (enabling this broadens permissions to every resource client;
  #                          review the upstream role assignments before turning it on)
  c.permission_role_scope = :default_resource
  # Optional whitelist of resource clients when `permission_role_scope = :all_resources`.
  # Leaving this as nil keeps the legacy "all clients" behavior, while providing
  # an explicit list (e.g., %w[rails-api verikloak-bff]) limits which clients can
  # contribute roles to permission checks.
  c.permission_resource_clients = nil

  # Expose `verikloak_claims` to views via helper_method (Rails only)
  c.expose_helper_method = true
end
```

### Working with other Verikloak gems

- **verikloak-bff**: When your Rails application sits behind the BFF, the access
  token presented to verikloak-pundit typically originates from the BFF
  (e.g. via the `x-verikloak-user` header). Make sure your Rack stack stores the
  decoded claims under the same `env_claims_key` configured above (the default
  `"verikloak.user"` works out of the box with `verikloak-bff >= 0.3`). If the
  BFF issues tokens for multiple downstream services, set
  `permission_resource_clients` to the limited list of clients whose roles should
  affect Rails-side authorization to avoid accidentally inheriting permissions
  meant for other services.
- **verikloak-audience**: Audience services often mint resource roles with a
  service-specific prefix (for example, `audience-service:editor`). Align your
  `role_map` keys with that naming convention so `user.has_permission?` resolves
  correctly. If Audience adds its own client entry inside `resource_access`, add
  that client id to `permission_resource_clients` when you need to consume those
  roles from Rails.

## Integrating with Database User Models

### Overview

`Verikloak::Pundit::UserContext` wraps JWT claims for use in Pundit policies. However, real applications often need to access database User models for additional attributes (e.g., `user.admin?`, `user.organization_id`).

### Custom UserContext Pattern

Create a custom UserContext that holds both JWT claims and a database user reference:

```ruby
# app/lib/app_user_context.rb
class AppUserContext < Verikloak::Pundit::UserContext
  attr_reader :db_user

  def initialize(claims, db_user: nil, config: nil)
    super(claims, config: config)
    @db_user = db_user
  end

  # Delegate database user methods
  delegate :admin?, :organization_id, :active?, to: :db_user, allow_nil: true

  # Custom authorization helpers
  def owns?(record)
    return false unless db_user && record
    record.respond_to?(:user_id) && db_user.id == record.user_id
  end

  def same_organization?(record)
    return false unless db_user && record
    record.respond_to?(:organization_id) && db_user.organization_id == record.organization_id
  end
end
```

### Controller Setup

Override `pundit_user` in your ApplicationController. This example assumes you are using `verikloak-rails`, which provides `current_user_claims` and related helpers:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Verikloak::Pundit::Controller  # Provides pundit_user and verikloak_claims

  # If using verikloak-rails for JWT verification:
  # include Verikloak::Rails::Controller  # Provides current_user_claims, current_subject, etc.

  def pundit_user
    @pundit_user ||= AppUserContext.new(
      verikloak_claims,  # From Verikloak::Pundit::Controller
      db_user: find_or_create_current_user,
      config: Verikloak::Pundit.config
    )
  end

  private

  def find_or_create_current_user
    # Extract subject from claims
    sub = verikloak_claims&.dig('sub')
    return nil unless sub

    User.find_or_create_by(sub: sub) do |user|
      user.email = verikloak_claims&.dig('email')
      user.name = verikloak_claims&.dig('name')
    end
  end
end
```

> **Note:** If you are also using `verikloak-rails`, you can use its `current_user_claims` method instead of `verikloak_claims`. Both provide access to the JWT claims from the Rack environment.

### Policy Example

Now your policies can use both JWT claims and database attributes:

```ruby
# app/policies/document_policy.rb
class DocumentPolicy < ApplicationPolicy
  def show?
    # Combine JWT roles with database attributes
    user.has_role?(:admin) || user.owns?(record) || user.same_organization?(record)
  end

  def update?
    user.admin? || user.owns?(record)  # Uses delegated db_user.admin?
  end

  def destroy?
    user.has_role?(:admin) && user.active?  # JWT role + DB attribute
  end
end
```

## Delegations Module

### Overview

`Verikloak::Pundit::Delegations` provides shortcut methods for role and permission checks in policies.

### Usage

Include in your ApplicationPolicy to access helpers directly:

```ruby
class ApplicationPolicy
  include Verikloak::Pundit::Delegations

  # Now you can use:
  # - has_role?(:admin)        instead of user.has_role?(:admin)
  # - in_group?(:editors)      instead of user.in_group?(:editors)
  # - resource_role?(client, role)
  # - has_permission?(:manage_all)
end
```

### Requirements

- The policy must have a `user` method that returns a `Verikloak::Pundit::UserContext` (or subclass)
- If `user` is `nil`, delegation methods will raise `NoMethodError`

### Compatibility with Custom UserContext

Delegations work with any class that inherits from `Verikloak::Pundit::UserContext`:

```ruby
# Works with AppUserContext (shown above)
class DocumentPolicy < ApplicationPolicy
  include Verikloak::Pundit::Delegations

  def update?
    has_role?(:admin) || has_permission?(:write_documents)
  end
end
```

### Handling nil user

For policies that may receive `nil` users (e.g., public endpoints), you **must** guard against nil before calling delegation methods:

```ruby
class PublicDocumentPolicy < ApplicationPolicy
  def show?
    return true if record.public?
    return false unless user  # Guard against nil user before using delegations

    has_role?(:viewer)
  end
end
```

Alternatively, create a helper method in your `ApplicationPolicy`:

```ruby
class ApplicationPolicy
  include Verikloak::Pundit::Delegations

  private

  def authenticated?
    !user.nil?
  end

  def safe_has_role?(role)
    authenticated? && has_role?(role)
  end
end
```

## Non-Rails / custom usage

```ruby
claims = { "sub" => "123", "email" => "a@b", "realm_access" => {"roles" => ["admin"]} }
ctx = Verikloak::Pundit::UserContext.new(claims, resource_client: "rails-api")

ctx.has_role?(:admin)             # => true
ctx.resource_role?(:"rails-api", :writer) # depends on resource_access
ctx.has_permission?(:manage_all)  # from role_map, realm or resource roles
```

## Testing
All pull requests and pushes are automatically tested with [RSpec](https://rspec.info/) and [RuboCop](https://rubocop.org/) via GitHub Actions.
See the CI badge at the top for current build status.

To run the test suite locally:

```bash
docker compose run --rm dev rspec
docker compose run --rm dev rubocop -a
```

When writing specs, call `Verikloak::Pundit.reset!` in your test teardown to ensure configuration changes do not leak between examples:

```ruby
RSpec.configure do |config|
  config.after { Verikloak::Pundit.reset! }
end
```

An additional integration check exercises the gem together with the latest `verikloak` and `verikloak-rails` releases. This runs in CI automatically, and you can execute it locally with:

```bash
docker compose run --rm -e BUNDLE_FROZEN=0 dev bash -lc '
  cd integration && \
  apk add --no-cache --virtual .integration-build-deps \
    build-base \
    linux-headers \
    openssl-dev \
    yaml-dev && \
  bundle config set --local path vendor/bundle && \
  bundle install --jobs 4 --retry 3 && \
  bundle exec ruby check.rb && \
  apk del .integration-build-deps
'
```

## Contributing
Bug reports and pull requests are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Security
If you find a security vulnerability, please follow the instructions in [SECURITY.md](SECURITY.md).

### Operational guidance
- Enabling `permission_role_scope = :all_resources` pulls roles from every Keycloak client in `resource_access`. Review the granted roles carefully to ensure you are not expanding permissions beyond what the application expects.
- Combine `permission_role_scope = :all_resources` with `permission_resource_clients`
  to explicitly opt-in the clients that may contribute permissions. Leaving the
  whitelist blank (the default) reverts to the legacy behavior of trusting
  every client in the token.
- Leaving `expose_helper_method = true` exposes `verikloak_claims` to the Rails view layer. If the claims include personal or sensitive data, consider switching it to `false` and pass only the minimum required information through controller-provided helpers.

## License
This project is licensed under the [MIT License](LICENSE).

## Publishing (for maintainers)
Gem release instructions are documented separately in [MAINTAINERS.md](MAINTAINERS.md).

## Changelog
See [CHANGELOG.md](CHANGELOG.md) for release history.

## References
- Verikloak (core): https://github.com/taiyaky/verikloak
- verikloak-rails (Rails integration): https://github.com/taiyaky/verikloak-rails
- verikloak-pundit on RubyGems: https://rubygems.org/gems/verikloak-pundit
