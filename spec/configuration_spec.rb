# frozen_string_literal: true

require "spec_helper"

RSpec.describe Verikloak::Pundit::Configuration do
  after do
    Verikloak::Pundit.reset!
  end

  it "has sensible defaults" do
    cfg = described_class.new
    expect(cfg.resource_client).to eq("rails-api")
    expect(cfg.role_map).to eq({})
    expect(cfg.env_claims_key).to eq("verikloak.user")
    expect(cfg.realm_roles_path).to eq(%w[realm_access roles])
    expect(cfg.resource_roles_path).to be_a(Array)
    expect(cfg.permission_role_scope).to eq(:default_resource)
    expect(cfg.permission_resource_clients).to be_nil
    expect(cfg.expose_helper_method).to be(true)
  end

  it "is configurable via Verikloak::Pundit.configure" do
    result = Verikloak::Pundit.configure do |c|
      c.resource_client = "api"
      c.role_map = { admin: :all }
      c.permission_role_scope = :all_resources
      c.permission_resource_clients = [:api, "rails-api"]
      c.expose_helper_method = false
    end
    expect(result).to be_a(described_class)
    expect(result).to be_frozen
    expect(result.resource_client).to be_frozen
    expect(result.role_map).to be_frozen
    expect(result.env_claims_key).to be_frozen
    expect(result.permission_resource_clients).to eq(%w[api rails-api])
    expect(result.permission_resource_clients).to be_frozen
    expect(result.expose_helper_method).to be(false)
    expect(Verikloak::Pundit.config.resource_client).to eq("api")
    expect(Verikloak::Pundit.config.role_map).to eq({ admin: :all })
    expect(Verikloak::Pundit.config.permission_role_scope).to eq(:all_resources)
    expect(Verikloak::Pundit.config.permission_resource_clients).to eq(%w[api rails-api])
    expect(Verikloak::Pundit.config.expose_helper_method).to be(false)
  end

  it "provides unfrozen copies when reconfiguring" do
    Verikloak::Pundit.configure do |c|
      c.resource_client = "api"
      c.role_map = { admin: :all }
    end

    Verikloak::Pundit.configure do |c|
      expect(c).not_to be_frozen
      expect(c.role_map).not_to be_frozen
      c.role_map[:reader] = :read
    end

    expect(Verikloak::Pundit.config.role_map).to eq({ admin: :all, reader: :read })
  end

  it "does not share nested configuration structures across publishes" do
    Verikloak::Pundit.configure do |c|
      c.role_map = { admin: [:manage_all] }
      c.realm_roles_path = ["roles", ["nested"]]
    end

    published = Verikloak::Pundit.config

    Verikloak::Pundit.configure do |c|
      c.role_map[:admin] << :additional
      c.realm_roles_path.last << "another"
    end

    expect(published.role_map[:admin]).to eq([:manage_all])
    expect(published.realm_roles_path).to eq(["roles", ["nested"]])
  end

  it "stringifies and de-duplicates permission_resource_clients" do
    cfg = described_class.new
    cfg.permission_resource_clients = [:api, :api, "rails-api"]
    finalized = cfg.dup.finalize!
    expect(finalized.permission_resource_clients).to eq(%w[api rails-api])
  end

  it "resets configuration to defaults" do
    Verikloak::Pundit.configure do |c|
      c.resource_client = "custom"
      c.role_map = { admin: :all }
    end

    Verikloak::Pundit.reset!

    expect(Verikloak::Pundit.config.resource_client).to eq("rails-api")
    expect(Verikloak::Pundit.config.role_map).to eq({})
  end
end
