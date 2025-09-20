# frozen_string_literal: true

require "spec_helper"

RSpec.describe Verikloak::Pundit::RoleMapper do
  it "returns role as-is when map is empty" do
    cfg = Verikloak::Pundit::Configuration.new
    expect(described_class.map("admin", cfg)).to eq("admin")
  end

  it "maps known roles via configuration" do
    cfg = Verikloak::Pundit::Configuration.new
    cfg.role_map = { admin: :manage_all }
    expect(described_class.map("admin", cfg)).to eq(:manage_all)
    expect(described_class.map(:reader, cfg)).to eq(:reader)
  end
end
