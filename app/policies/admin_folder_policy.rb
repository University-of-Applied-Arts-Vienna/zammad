# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AdminFolderPolicy < ApplicationPolicy
  def show?
    permitted?
  end

  def create?
    permitted?
  end

  def update?
    permitted?
  end

  def destroy?
    permitted?
  end

  private

  # Folders are managed by the admin of the folder's target object type, e.g. a
  #   trigger folder requires the 'admin.trigger' permission.
  def permitted?
    permission = record.required_permission
    return false if permission.nil?

    user.permissions?(permission)
  end
end
