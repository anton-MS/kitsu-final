class MediaAttributePolicy < ApplicationPolicy
  administrated_by :database_mod

  def create?
    false
  end
  alias_method :update?, :create?
  alias_method :destroy?, :create?
end