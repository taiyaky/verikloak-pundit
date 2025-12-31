# frozen_string_literal: true

require_relative 'lib/verikloak/pundit/version'

Gem::Specification.new do |spec|
  spec.name          = 'verikloak-pundit'
  spec.version       = Verikloak::Pundit::VERSION
  spec.authors       = ['taiyaky']

  spec.summary       = 'Pundit integration for Keycloak roles via Verikloak'
  spec.description   = 'Maps Keycloak JWT roles to a Pundit-friendly UserContext with helpers and a Rails generator.'

  spec.homepage      = 'https://github.com/taiyaky/verikloak-pundit'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb'] + %w[README.md LICENSE CHANGELOG.md]
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1'

  # Runtime dependencies
  spec.add_dependency 'pundit', '~> 2.3'
  spec.add_dependency 'rack', '>= 2.2', '< 4.0'
  spec.add_dependency 'verikloak', '>= 0.3.0', '< 1.0.0'

  # Metadata for RubyGems
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/verikloak-pundit/#{Verikloak::Pundit::VERSION}"
  spec.metadata['rubygems_mfa_required'] = 'true'
end
