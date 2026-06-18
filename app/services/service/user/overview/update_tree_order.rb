# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Stores the personal overview/folder order for the current user. `entries` is
#   the full, already-authorized list of tree nodes in display (depth-first)
#   order, each a hash `{ type: 'Overview' | 'OverviewFolder', id: Integer }`;
#   the index in the list becomes the shared prio, so folders and overviews
#   interleave correctly at every level of the sidebar tree.
class Service::User::Overview::UpdateTreeOrder < Service::Base
  requires_current_user!

  attr_reader :entries

  def initialize(entries)
    @entries = entries
  end

  def execute
    ActiveRecord::Base.transaction do
      reset_existing
      create_new
    end
  end

  private

  def reset_existing
    ::User::OverviewSorting.where(user: current_user).destroy_all
    ::User::OverviewFolderSorting.where(user: current_user).destroy_all
  end

  def create_new
    entries.each_with_index do |entry, index|
      prio = index + 1

      case entry[:type]
      when 'Overview'
        ::User::OverviewSorting.create!(user: current_user, overview_id: entry[:id], prio:)
      when 'OverviewFolder'
        ::User::OverviewFolderSorting.create!(user: current_user, overview_folder_id: entry[:id], prio:)
      end
    end
  end
end
