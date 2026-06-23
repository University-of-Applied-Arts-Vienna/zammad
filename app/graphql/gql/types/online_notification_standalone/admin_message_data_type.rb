# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::OnlineNotificationStandalone
  class AdminMessageDataType < Gql::Types::BaseObject
    description 'Data payload for admin message standalone notifications'

    field :message, String, null: false
    field :admin_message_id, Integer, null: false
  end
end
