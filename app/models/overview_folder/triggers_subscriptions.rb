# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module OverviewFolder::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  private

  # Folder changes affect how overviews are grouped in the agent UI, so reuse
  #   the existing overview subscriptions to make clients refetch their data.
  def trigger_subscriptions
    [true, false].each do |ignore_user_conditions|
      Gql::Subscriptions::Ticket::OverviewUpdates.trigger(nil, arguments: { ignore_user_conditions: })
      Gql::Subscriptions::User::Current::Ticket::OverviewUpdates.trigger(nil, arguments: { ignore_user_conditions: })
    end
  end
end
