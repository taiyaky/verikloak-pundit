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
- **Helpers**: `has_role?`, `in_group?`, `resource_role?(client, role)`
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
  #                         (※ すべてのリソースクライアントのロールが権限候補になるため、
  #                            想定外の権限が付与されないよう設定前に要確認)
  c.permission_role_scope = :default_resource

  # Expose `verikloak_claims` to views via helper_method (Rails only)
  # (※ 個人情報を含むクレームをテンプレートに公開するため、不要なら false を推奨)
  c.expose_helper_method = true
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

An additional integration check exercises the gem together with the latest
`verikloak` and `verikloak-rails` releases. This runs in CI automatically, and
you can execute it locally with:

```bash
docker compose run --rm dev bash -lc 'cd integration && bundle update && bundle exec ruby check.rb'
```

## Contributing
Bug reports and pull requests are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Security
If you find a security vulnerability, please follow the instructions in [SECURITY.md](SECURITY.md).

### Operational guidance
- `permission_role_scope = :all_resources` を有効にすると、Keycloak のすべてのクライアントに付与されたロールが権限候補になります。アプリケーションで不要な権限が紛れ込まないよう、利用前に付与範囲を十分に確認してください。
- `expose_helper_method = true` のままにすると `verikloak_claims` が Rails のビュー層へ公開されます。個人情報や機微情報を含むクレームをテンプレートから直接参照したくない場合は `false` に変更し、必要最小限のデータだけをコントローラ経由で渡す運用を検討してください。

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
