# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OverviewFolderType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField

    description 'Folders grouping ticket overviews'

    field :name, String, null: false
    field :prio, Integer, null: false
    field :parent_id, Integer, null: true, description: 'Internal ID of the parent folder, if any'
    field :active, Boolean, null: false
  end
end
