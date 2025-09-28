# frozen_string_literal: true

require "spec_helper"

RSpec.describe Verikloak::Pundit::Policy do
  let(:dummy_policy_class) do
    Class.new do
      include Verikloak::Pundit::Policy

      attr_reader :user

      def initialize(user)
        @user = user
      end
    end
  end

  let(:user) do
    double(
      has_role?: true,
      in_group?: false,
      resource_role?: true,
      has_permission?: false
    )
  end

  before do
    allow(Verikloak::Pundit::Policy).to receive(:warn)
  end

  it "delegates helper methods to user" do
    p = dummy_policy_class.new(user)

    expect(Verikloak::Pundit::Policy).to have_received(:warn).with(
      '[DEPRECATED] Verikloak::Pundit::Policy is deprecated. Include Verikloak::Pundit::Delegations directly instead. This will be removed in v1.0.0.'
    )

    expect(p.has_role?(:admin)).to be true
    expect(p.in_group?(:staff)).to be false
    expect(p.resource_role?(:client, :role)).to be true
    expect(p.has_permission?(:perm)).to be false
  end
end
