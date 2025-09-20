# frozen_string_literal: true

require 'bundler/setup'

require 'verikloak'

begin
  require 'verikloak/rails'
rescue LoadError
  require 'verikloak-rails'
end

require 'verikloak/pundit'

# Sanity-check top-level modules resolved from the required gems.
raise 'Verikloak module missing' unless defined?(Verikloak)
raise 'Verikloak::Rails missing' unless defined?(Verikloak::Rails)
raise 'Verikloak::Pundit missing' unless defined?(Verikloak::Pundit)

# Ensure a UserContext can be built from a Rack env populated by verikloak.
claims = { 'realm_access' => { 'roles' => %w[viewer] } }
user = Verikloak::Pundit::UserContext.new(claims, config: Verikloak::Pundit::Configuration.new)
raise 'UserContext failed to expose roles' unless user.roles.include?('viewer')

env = { 'verikloak.user' => claims }
user_from_env = Verikloak::Pundit::UserContext.from_env(env)
raise 'UserContext.from_env failed' unless user_from_env.roles == user.roles

puts 'verikloak + verikloak-rails integration check passed'
