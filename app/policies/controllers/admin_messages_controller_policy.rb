# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AdminMessagesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit! ['admin.message']

  # The banner is shown to every authenticated user, so the read-only `current`
  # action must be reachable by agents and customers as well.
  permit! %i[current], to: ['ticket.agent', 'ticket.customer']
end
