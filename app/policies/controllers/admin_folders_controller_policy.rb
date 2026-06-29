# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AdminFoldersControllerPolicy < Controllers::ApplicationControllerPolicy
  # Listing/searching folders is allowed for any admin that manages at least one
  #   foldered object type; the client filters the folders per object type.
  default_permit!(AdminFolder::TARGET_MODELS.values)

  def create?
    permitted_for_target_model?(record.params[:target_model])
  end

  def update?
    permitted_for_existing_folder?
  end

  def destroy?
    permitted_for_existing_folder?
  end

  private

  def permitted_for_existing_folder?
    folder = AdminFolder.find_by(id: record.params[:id])
    return false if folder.nil?

    permitted_for_target_model?(folder.target_model)
  end

  def permitted_for_target_model?(target_model)
    permission = AdminFolder::TARGET_MODELS[target_model]
    return false if permission.nil?

    user.permissions?(permission)
  end
end
