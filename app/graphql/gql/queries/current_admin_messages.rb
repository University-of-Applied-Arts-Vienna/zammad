# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class CurrentAdminMessages < BaseQuery

    description 'Admin messages currently shown to the requesting user'

    type [Gql::Types::AdminMessageType], null: false

    def resolve(...)
      AdminMessage.current_for(context.current_user)
    end
  end
end
