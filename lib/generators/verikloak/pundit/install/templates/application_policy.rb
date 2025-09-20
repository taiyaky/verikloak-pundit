# frozen_string_literal: true

# Base Pundit policy for applications using verikloak-pundit.
#
# This class is intended as a starting point. Override per-action
# predicates (e.g., show?, update?) in your concrete policies.
class ApplicationPolicy
  attr_reader :user, :record

  # `user` is a Verikloak::Pundit::UserContext
  # @param user [Object] Pundit user (UserContext when using verikloak-pundit)
  # @param record [Object] The resource being authorized
  def initialize(user, record)
    @user = user
    @record = record
  end

  # @return [Boolean]
  def index?    = false
  # @return [Boolean]
  def show?     = false
  # @return [Boolean]
  def create?   = false
  # @return [Boolean]
  def new?      = create?
  # @return [Boolean]
  def update?   = false
  # @return [Boolean]
  def edit?     = update?
  # @return [Boolean]
  def destroy?  = false

  # Default scope for application policies.
  class Scope
    attr_reader :user, :scope

    # @param user [Object] Pundit user (UserContext)
    # @param scope [Class,Array] model class or dataset
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # @return [Object] resolved scope
    def resolve
      scope.all
    end
  end
end
