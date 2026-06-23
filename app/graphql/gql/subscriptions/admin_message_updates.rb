# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class AdminMessageUpdates < BaseSubscription

    description 'Notifies clients that admin messages changed, so they can refetch the current ones'

    broadcastable true

    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true, description: 'Time of the change'

    def update
      object
    end
  end
end
