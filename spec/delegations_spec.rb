# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Verikloak::Pundit::Delegations do
  after do
    Verikloak::Pundit.reset!
  end

  let(:claims) do
    {
      'sub' => 'abc',
      'realm_access' => { 'roles' => ['admin'] },
      'resource_access' => { 'rails-api' => { 'roles' => ['editor'] } }
    }
  end

  let(:policy_class) do
    Class.new do
      include Verikloak::Pundit::Delegations

      attr_reader :user

      def initialize(user)
        @user = user
      end
    end
  end

  let(:user) { Verikloak::Pundit::UserContext.new(claims) }
  let(:policy) { policy_class.new(user) }

  it 'delegates has_role? to the user context' do
    expect(policy.has_role?(:admin)).to be true
    expect(policy.has_role?(:ghost)).to be false
  end

  it 'delegates in_group? to the user context' do
    expect(policy.in_group?('admin')).to be true
    expect(policy.in_group?(:ghost)).to be false
  end

  it 'delegates resource_role? to the user context' do
    expect(policy.resource_role?(:'rails-api', :editor)).to be true
    expect(policy.resource_role?(:other, :editor)).to be false
  end

  it 'delegates has_permission? to the user context' do
    Verikloak::Pundit.configure { |c| c.role_map = { admin: :manage_all } }

    expect(policy.has_permission?(:manage_all)).to be true
    expect(policy.has_permission?(:something_else)).to be false
  end

  it 'raises NoMethodError when user is nil (documented requirement)' do
    nil_policy = policy_class.new(nil)
    expect { nil_policy.has_role?(:admin) }.to raise_error(NoMethodError)
  end
end
