# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Verikloak::Pundit::RoleMapper do
  it 'returns role as-is when map is empty' do
    cfg = Verikloak::Pundit::Configuration.new
    expect(described_class.map('admin', cfg)).to eq('admin')
  end

  it 'maps known roles via configuration' do
    cfg = Verikloak::Pundit::Configuration.new
    cfg.role_map = { admin: :manage_all }
    expect(described_class.map('admin', cfg)).to eq(:manage_all)
    expect(described_class.map(:reader, cfg)).to eq(:reader)
  end

  describe '.permission_for' do
    it 'returns the mapped permission when the role is mapped' do
      cfg = Verikloak::Pundit::Configuration.new
      cfg.role_map = { admin: :manage_all }
      expect(described_class.permission_for('admin', cfg)).to eq(:manage_all)
    end

    it 'falls back to the role itself when unmapped and strict mode is off' do
      cfg = Verikloak::Pundit::Configuration.new
      expect(described_class.permission_for('reader', cfg)).to eq('reader')
    end

    it 'returns nil for unmapped roles when strict mode is on' do
      cfg = Verikloak::Pundit::Configuration.new
      cfg.role_map = { admin: :manage_all }
      cfg.strict_permissions = true
      expect(described_class.permission_for('reader', cfg)).to be_nil
      expect(described_class.permission_for('admin', cfg)).to eq(:manage_all)
    end
  end
end
