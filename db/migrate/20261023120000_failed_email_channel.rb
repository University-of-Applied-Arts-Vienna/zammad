# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FailedEmailChannel < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Systems set up from the base migration have no timestamps on this table.
    if !column_exists?(:failed_emails, :created_at)
      add_timestamps :failed_emails, limit: 3, null: true
      execute 'UPDATE failed_emails SET created_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP'
      change_column_null :failed_emails, :created_at, false
      change_column_null :failed_emails, :updated_at, false
    end

    if !column_exists?(:failed_emails, :channel_id)
      add_reference :failed_emails, :channel, type: :integer, null: true, foreign_key: { on_delete: :nullify }
    end

    FailedEmail.reset_column_information
  end
end
