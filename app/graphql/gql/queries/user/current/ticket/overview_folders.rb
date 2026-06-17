# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::Ticket::OverviewFolders < BaseQuery

    description 'Folders grouping the ticket overviews visible to the current user'

    argument :ignore_user_conditions, Boolean, description: 'Include folders of additional overviews by ignoring user conditions'

    type [Gql::Types::OverviewFolderType], null: false

    def resolve(ignore_user_conditions:)
      Service::User::Overview::Folder::List.with_current_user(context.current_user).execute(ignore_user_conditions:)
    end
  end
end
