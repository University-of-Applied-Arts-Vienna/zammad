# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Notify GraphQL clients that the set of admin messages changed, so they can
# refetch the messages currently relevant for them.
module AdminMessage::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  def trigger_subscriptions
    self.class.trigger_subscriptions
  end

  class_methods do
    def trigger_subscriptions
      Gql::Subscriptions::AdminMessageUpdates.trigger({ updated_at: Time.zone.now })
    end
  end
end
