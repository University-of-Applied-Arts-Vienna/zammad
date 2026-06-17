# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue4965FollowUpNewTicketForDifferentGroup < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '0201_postmaster_filter_follow_up_group_check',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to create a new ticket in the receiving group if a follow-up is detected for a different group.',
      options:     {},
      state:       'Channel::Filter::FollowUpGroupCheck',
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       'New ticket for follow-up to a different group',
      name:        'postmaster_follow_up_new_ticket_for_different_group',
      area:        'Email::Base',
      description: 'If a follow-up is detected (e.g. via subject or References header) for a ticket that belongs to a different group than the receiving channel/address, create a new ticket in the receiving group instead of appending to the existing ticket.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'postmaster_follow_up_new_ticket_for_different_group',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
      },
      frontend:    false
    )
  end
end
