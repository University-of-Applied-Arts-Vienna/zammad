# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Returns the folders that should be visible to the current user, i.e. every
#   folder (and its ancestor chain) that contains at least one overview the user
#   may use. Folders without any visible overview are pruned.
class Service::User::Overview::Folder::List < Service::Base
  requires_current_user!

  attr_reader :ignore_user_conditions

  def initialize(ignore_user_conditions:)
    @ignore_user_conditions = ignore_user_conditions
  end

  def execute
    folder_ids_with_visible_overview = Ticket::OverviewsPolicy::Scope
      .new(current_user, Overview)
      .resolve(ignore_user_conditions:)
      .where.not(folder_id: nil)
      .distinct
      .pluck(:folder_id)

    return OverviewFolder.none if folder_ids_with_visible_overview.empty?

    active_folders_by_id = OverviewFolder.where(active: true).index_by(&:id)

    visible_folder_ids = Set.new
    folder_ids_with_visible_overview.each do |folder_id|
      current_id = folder_id

      # Walk up the ancestor chain, stopping at the root, an already-seen
      #   folder, or an inactive/missing folder (which breaks the branch).
      while current_id && (folder = active_folders_by_id[current_id]) && visible_folder_ids.exclude?(current_id)
        visible_folder_ids << current_id
        current_id = folder.parent_id
      end
    end

    OverviewFolder.where(id: visible_folder_ids.to_a).reorder(:prio, :id)
  end
end
