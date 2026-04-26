class DiaryPolicy < ApplicationPolicy
  def index?   = true
  def show?    = owner?
  def new?     = create?
  def create?  = true
  def edit?    = update?
  def update?  = owner?
  def destroy? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def owner?
    record.user_id == user.id
  end
end
