# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Admin-only folders to organize admin objects (triggers, core workflows, text
#   modules, macros, schedulers, ...) within the admin interface. Each folder
#   belongs to exactly one target model, so every object type has its own,
#   independent folder tree. Folders can be nested.
class AdminFolder < ApplicationModel
  include HasDefaultModelUserRelations

  include ChecksClientNotification
  include CanPriorization
  include CanSelector
  include CanSearch

  include AdminFolder::Assets

  # Object types that can be organized into admin folders, mapped to the admin
  #   permission required to manage their folders.
  TARGET_MODELS = {
    'Trigger'      => 'admin.trigger',
    'CoreWorkflow' => 'admin.core_workflow',
    'TextModule'   => 'admin.text_module',
    'Macro'        => 'admin.macro',
    'Job'          => 'admin.scheduler',
  }.freeze

  belongs_to :parent, class_name: 'AdminFolder', optional: true, inverse_of: :children
  has_many   :children, class_name: 'AdminFolder', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

  validates :name,         presence: true
  validates :target_model, presence: true, inclusion: { in: TARGET_MODELS.keys }
  validate  :validate_parent

  before_destroy :nullify_items

  # Admin permission required to manage folders of this folder's target model.
  def required_permission
    TARGET_MODELS[target_model]
  end

  # Returns the chain of ancestors of this folder, starting with the direct parent.
  def ancestors
    result = []
    current = parent
    while current
      break if result.include?(current) # safety net against pre-existing cycles

      result << current
      current = current.parent
    end
    result
  end

  # Returns all transitive descendant folders of this folder.
  def descendants
    children.flat_map { |child| [child, *child.descendants] }
  end

  private

  def validate_parent
    return if parent_id.blank?

    if parent_id == id
      errors.add(:parent_id, __('A folder cannot be its own parent.'))
      return
    end

    parent_folder = AdminFolder.find_by(id: parent_id)
    if parent_folder && parent_folder.target_model != target_model
      errors.add(:parent_id, __('A folder can only be nested within a folder of the same type.'))
      return
    end

    return if ancestors.none? { |folder| folder.id == id }

    errors.add(:parent_id, __('A folder cannot be moved into one of its own subfolders.'))
  end

  # Detach the folder's objects (they fall back to the root level) before the
  #   folder is removed, so the foreign key constraint is not violated.
  def nullify_items
    return if target_model.blank?

    target_model.constantize.where(admin_folder_id: id).update_all(admin_folder_id: nil) # rubocop:disable Rails/SkipsModelValidations
  end
end
