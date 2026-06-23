# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class AdminMessageType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields

    description 'Admin message shown as a warning banner to targeted users'

    field :message, String, null: false
    field :start_at, GraphQL::Types::ISO8601DateTime, null: false
    field :end_at, GraphQL::Types::ISO8601DateTime, null: false
    field :active, Boolean, null: false
  end
end
