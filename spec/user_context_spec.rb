# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Verikloak::Pundit::UserContext do
  after do
    Verikloak::Pundit.reset!
  end

  let(:claims) do
    {
      'sub' => 'abc',
      'email' => 'u@example.com',
      'realm_access' => { 'roles' => %w[admin reader] },
      'resource_access' => { 'rails-api' => { 'roles' => ['editor'] } }
    }
  end

  it 'reads realm roles' do
    ctx = described_class.new(claims)
    expect(ctx.has_role?(:admin)).to be true
    expect(ctx.in_group?('reader')).to be true
  end

  it 'reads resource roles' do
    ctx = described_class.new(claims)
    expect(ctx.resource_role?(:'rails-api', :editor)).to be true
  end

  it 'resolves explicitly requested clients with the default resource_roles_path' do
    multi_client_claims = {
      'resource_access' => {
        'rails-api' => { 'roles' => ['editor'] },
        'other-api' => { 'roles' => ['viewer'] }
      }
    }
    ctx = described_class.new(multi_client_claims)

    expect(ctx.resource_role?(:'other-api', :viewer)).to be true
    # Regression: the default path lambda used to ignore the client argument
    # and always dig into the default resource client's roles.
    expect(ctx.resource_role?(:'other-api', :editor)).to be false
    expect(ctx.resource_role?(:missing, :viewer)).to be false
  end

  it 'respects configurable resource_roles_path with client override' do
    # Configure path to accept (config, client) for dynamic segment
    Verikloak::Pundit.configure do |c|
      c.resource_client = 'rails-api'
      c.resource_roles_path = [
        'resource_access',
        ->(cfg, client) { client || cfg.resource_client },
        'roles'
      ]
    end

    test_claims = {
      'resource_access' => {
        'another' => { 'roles' => ['writer'] }
      }
    }
    ctx = described_class.new(test_claims)
    expect(ctx.resource_role?(:another, :writer)).to be true
  end

  it 'passes the requested client to path lambdas with optional parameters' do
    Verikloak::Pundit.configure do |c|
      c.resource_client = 'rails-api'
      c.resource_roles_path = [
        'resource_access',
        ->(cfg, client = nil) { client || cfg.resource_client },
        'roles'
      ]
    end

    multi_client_claims = {
      'resource_access' => {
        'rails-api' => { 'roles' => ['editor'] },
        'other-api' => { 'roles' => ['viewer'] }
      }
    }
    ctx = described_class.new(multi_client_claims)

    # Regression: the old `arity >= 2` dispatch skipped the client for
    # optional-parameter lambdas (arity -2), silently checking the default
    # client's roles instead of the requested one.
    expect(ctx.resource_role?(:'other-api', :viewer)).to be true
    expect(ctx.resource_role?(:'other-api', :editor)).to be false
  end

  it 'maps permissions from realm and resource roles' do
    Verikloak::Pundit.configure do |c|
      c.role_map = {
        admin: :manage_all,
        editor: :write_notes
      }
      c.resource_client = 'rails-api'
    end

    ctx = described_class.new(claims)
    expect(ctx.has_permission?(:manage_all)).to be true      # from realm role :admin
    expect(ctx.has_permission?('write_notes')).to be true    # from resource role :editor
  end

  it 'can include roles from all resource clients when opted in' do
    claims2 = {
      'realm_access' => { 'roles' => [] },
      'resource_access' => {
        'rails-api' => { 'roles' => [] },
        'another' => { 'roles' => ['writer'] }
      }
    }
    Verikloak::Pundit.configure do |c|
      c.role_map = { writer: :write_notes }
      c.permission_role_scope = :all_resources
      c.permission_resource_clients = nil
    end

    ctx = described_class.new(claims2)
    expect(ctx.has_permission?(:write_notes)).to be true
  end

  it 'can restrict all_resources scope to configured clients' do
    claims2 = {
      'realm_access' => { 'roles' => [] },
      'resource_access' => {
        'rails-api' => { 'roles' => [] },
        'another' => { 'roles' => ['writer'] }
      }
    }
    Verikloak::Pundit.configure do |c|
      c.role_map = { writer: :write_notes }
      c.permission_role_scope = :all_resources
      c.permission_resource_clients = ['rails-api']
    end

    ctx = described_class.new(claims2)
    expect(ctx.has_permission?(:write_notes)).to be false
  end

  it 'falls back to preferred_username for email when email missing' do
    c = { 'preferred_username' => 'foo' }
    ctx = described_class.new(c)
    expect(ctx.email).to eq('foo')
  end

  it 'in_group? behaves like has_role?' do
    c = { 'realm_access' => { 'roles' => ['group1'] } }
    ctx = described_class.new(c)
    expect(ctx.has_role?(:group1)).to be true
    expect(ctx.in_group?(:group1)).to be true
  end

  it 'has_permission? returns false when unmapped and unmatched' do
    Verikloak::Pundit.configure { |cfg| cfg.role_map = {} }
    ctx = described_class.new(claims)
    expect(ctx.has_permission?(:something_else)).to be false
  end

  it 'respects realm_roles_path customization' do
    Verikloak::Pundit.configure do |cfg|
      cfg.realm_roles_path = ['roles']
    end
    c = { 'roles' => ['alpha'] }
    ctx = described_class.new(c)
    expect(ctx.realm_roles).to eq(['alpha'])
  end

  it 'uses default resource_client when none given' do
    Verikloak::Pundit.configure { |cfg| cfg.resource_client = 'rails-api' }
    ctx = described_class.new(claims)
    expect(ctx.resource_roles).to include('editor')
  end

  it 'returns empty resource roles when path missing' do
    ctx = described_class.new({})
    expect(ctx.resource_roles).to eq([])
  end

  it 'handles nil or non-Hash claims safely' do
    ctx = described_class.new(nil)
    expect(ctx.sub).to be_nil
    expect(ctx.email).to be_nil
    expect(ctx.realm_roles).to eq([])
    expect(ctx.resource_roles).to eq([])
    expect(ctx.has_role?(:admin)).to be false
    expect(ctx.resource_role?(:any, :role)).to be false
    expect(ctx.has_permission?(:anything)).to be false
  end

  it 'normalizes claim-like objects responding to to_hash' do
    claim_like = Struct.new(:data) do
      def to_hash
        { 'sub' => '123', 'realm_access' => { 'roles' => ['viewer'] } }
      end
    end.new(nil)

    ctx = described_class.new(claim_like)
    expect(ctx.sub).to eq('123')
    expect(ctx.has_role?(:viewer)).to be true
  end

  it 'supports role_map with mixed key/value types' do
    Verikloak::Pundit.configure do |c|
      c.role_map = { admin: 'manage_all', editor: :write_notes }
    end
    c2 = {
      'realm_access' => { 'roles' => ['admin'] },
      'resource_access' => { 'rails-api' => { 'roles' => ['editor'] } }
    }
    ctx = described_class.new(c2)
    expect(ctx.has_permission?(:manage_all)).to be true
    expect(ctx.has_permission?(:write_notes)).to be true
  end

  it 'uses a consistent configuration snapshot for its lifetime' do
    Verikloak::Pundit.configure do |c|
      c.role_map = { admin: :manage_all }
    end
    ctx = described_class.new(claims)
    expect(ctx.has_permission?(:manage_all)).to be true

    # Change global configuration after context construction
    Verikloak::Pundit.configure do |c|
      c.role_map = {}
    end

    # Previously granted permission should still be mapped because the
    # context holds a snapshot of the original configuration.
    expect(ctx.has_permission?(:manage_all)).to be true
  end

  it 'handles non-hash entries in resource_access gracefully' do
    Verikloak::Pundit.configure do |c|
      c.permission_role_scope = :all_resources
    end

    malformed_claims = {
      'sub' => 'abc',
      'resource_access' => {
        'valid-client' => { 'roles' => ['editor'] },
        'malformed-client' => 'not a hash',
        'null-client' => nil
      }
    }

    ctx = described_class.new(malformed_claims)
    # Should extract roles from valid entry only
    roles = ctx.send(:resource_roles_all_clients)
    expect(roles).to eq(['editor'])
  end

  it 'maps permissions with string keys in role_map' do
    Verikloak::Pundit.configure do |c|
      c.role_map = { 'admin' => :manage_all }
    end

    ctx = described_class.new(claims)
    expect(ctx.has_permission?(:manage_all)).to be true
  end

  describe 'strict permissions' do
    it 'treats unmapped roles as permissions by default' do
      ctx = described_class.new(claims)
      expect(ctx.has_permission?(:reader)).to be true
    end

    it 'only grants mapped permissions when strict_permissions is enabled' do
      Verikloak::Pundit.configure do |c|
        c.role_map = { admin: :manage_all }
        c.strict_permissions = true
      end

      ctx = described_class.new(claims)
      expect(ctx.has_permission?(:manage_all)).to be true   # mapped realm role :admin
      expect(ctx.has_permission?(:admin)).to be false       # bare role name not a permission
      expect(ctx.has_permission?(:reader)).to be false      # unmapped realm role
      expect(ctx.has_permission?(:editor)).to be false      # unmapped resource role
    end

    it 'revokes implicit permissions for roles explicitly mapped to nil' do
      Verikloak::Pundit.configure do |c|
        c.role_map = { reader: nil }
      end

      ctx = described_class.new(claims)
      expect(ctx.has_permission?(:reader)).to be false
      # Other unmapped roles still fall through in non-strict mode
      expect(ctx.has_permission?(:admin)).to be true
      expect(ctx.has_permission?(:editor)).to be true
    end
  end

  describe '.from_env' do
    it 'builds an empty context from a nil env' do
      ctx = described_class.from_env(nil)
      expect(ctx.sub).to be_nil
      expect(ctx.realm_roles).to eq([])
    end

    it 'reads claims from the configured env key' do
      ctx = described_class.from_env({ 'verikloak.user' => claims })
      expect(ctx.sub).to eq('abc')
      expect(ctx.has_role?(:admin)).to be true
    end
  end
end
