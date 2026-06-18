# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OverviewFolder < ApplicationModel
  include HasDefaultModelUserRelations

  include ChecksClientNotification
  include CanSeed
  include CanPriorization
  include CanSelector
  include CanSearch

  include OverviewFolder::Assets
  include OverviewFolder::TriggersSubscriptions

  belongs_to :parent, class_name: 'OverviewFolder', optional: true, inverse_of: :children
  has_many   :children, class_name: 'OverviewFolder', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many   :overviews, inverse_of: :folder, dependent: :nullify
  has_many   :overview_folder_sortings, class_name: 'User::OverviewFolderSorting', dependent: :destroy

  validates :name, presence: true
  validate  :validate_parent

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

  # Lookup of all active folders indexed by id, used to resolve breadcrumbs
  #   without running a query per ancestor.
  def self.active_lookup
    where(active: true).index_by(&:id)
  end

  # Active-folder breadcrumb (root -> leaf) for the given folder id, resolved via
  #   a preloaded active-folder lookup (see .active_lookup). The walk up the
  #   ancestor chain stops at the first inactive/missing folder, mirroring the
  #   visibility rules of Service::User::Overview::Folder::List. Returns an empty
  #   array when the folder itself is inactive or missing.
  def self.breadcrumb(folder_id, active_lookup)
    chain = []
    current_id = folder_id

    while current_id && (folder = active_lookup[current_id]) && chain.none? { |existing| existing.id == folder.id }
      chain.unshift(folder)
      current_id = folder.parent_id
    end

    chain
  end

  private

  def validate_parent
    return if parent_id.blank?

    if parent_id == id
      errors.add(:parent_id, __('A folder cannot be its own parent.'))
      return
    end

    if ancestors.any? { |folder| folder.id == id }
      errors.add(:parent_id, __('A folder cannot be moved into one of its own subfolders.'))
    end
  end
end
