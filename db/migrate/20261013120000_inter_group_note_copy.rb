# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class InterGroupNoteCopy < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Defines transaction backend.',
      name:        '0110_inter_group_note_copy',
      area:        'Transaction::Backend::Async',
      description: 'Defines the transaction backend to copy public notes into the ticket of the group a request was sent from.',
      options:     {},
      state:       'Transaction::InterGroupNoteCopy',
      frontend:    false
    )
  end
end
