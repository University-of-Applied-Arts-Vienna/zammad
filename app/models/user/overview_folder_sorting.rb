# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewFolderSorting < ApplicationModel
  include HasDefaultModelUserRelations
  include CanPriorization

  belongs_to :user, class_name: 'User'
  belongs_to :overview_folder, inverse_of: :overview_folder_sortings

  default_scope { order(:prio, :id) }
end
