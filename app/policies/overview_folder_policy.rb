# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OverviewFolderPolicy < ApplicationPolicy
  def show?
    user_is_admin?
  end

  def create?
    user_is_admin?
  end

  def update?
    user_is_admin?
  end

  def destroy?
    user_is_admin?
  end

  private

  def user_is_admin?
    user.permissions?('admin.overview')
  end
end
