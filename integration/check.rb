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
claims = {
  'realm_access' => { 'roles' => %w[viewer admin] },
  'resource_access' => {
    'rails-api' => { 'roles' => %w[editor reporter] },
    'analytics' => { 'roles' => %w[writer] }
  }
}

Verikloak::Pundit.configure do |config|
  config.resource_client = 'rails-api'
  config.role_map = {
    viewer: :read_notes,
    editor: :write_notes,
    writer: :publish_insights
  }
  config.permission_role_scope = :default_resource
  config.expose_helper_method = true
end

user = Verikloak::Pundit::UserContext.new(claims)
raise 'UserContext failed to expose realm roles' unless user.realm_roles.sort == %w[admin viewer]
raise 'UserContext failed to expose resource roles' unless user.resource_roles.sort == %w[editor reporter]
raise 'UserContext failed to expose configured permissions' unless user.has_permission?(:write_notes)

env = { 'verikloak.user' => claims }
user_from_env = Verikloak::Pundit::UserContext.from_env(env)
raise 'UserContext.from_env failed' unless user_from_env.realm_roles.sort == user.realm_roles.sort
raise 'UserContext.from_env lost resource roles' unless user_from_env.resource_roles.sort == user.resource_roles.sort
raise 'UserContext.from_env lost permissions' unless user_from_env.has_permission?(:write_notes)

# Ensure :all_resources scope brings in roles from every resource client
Verikloak::Pundit.configure do |config|
  config.permission_role_scope = :all_resources
end
user_all_resources = Verikloak::Pundit::UserContext.new(claims)
unless user_all_resources.has_permission?(:publish_insights)
  raise 'UserContext failed to include roles from all resources'
end

# Helper exposure should respect configuration flag
klass = Class.new do
  class << self
    attr_reader :helper_method_calls

    def helper_method(*args)
      (@helper_method_calls ||= []) << args
    end
  end

  include Verikloak::Pundit::Controller
end
raise 'Controller failed to expose helper when enabled' unless klass.helper_method_calls&.include?([:verikloak_claims])

Verikloak::Pundit.configure do |config|
  config.expose_helper_method = false
end
klass = Class.new do
  class << self
    attr_reader :helper_method_calls

    def helper_method(*args)
      (@helper_method_calls ||= []) << args
    end
  end

  include Verikloak::Pundit::Controller
end
raise 'Controller exposed helper despite being disabled' if klass.helper_method_calls

# Restore defaults after integration checks
Verikloak::Pundit.configure do |config|
  config.resource_client = 'rails-api'
  config.role_map = {}
  config.permission_role_scope = :default_resource
  config.expose_helper_method = true
end

puts 'verikloak + verikloak-rails integration check passed'
