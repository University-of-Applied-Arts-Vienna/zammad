# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CreateAdminMessages < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_admin_messages_table
    create_admin_messages_groups_table
    create_admin_message_permission
    create_admin_message_scheduler
  end

  private

  def create_admin_messages_table
    create_table :admin_messages, id: :integer do |t|
      t.text :message, null: false

      t.timestamp :start_at, limit: 3, null: false
      t.timestamp :end_at,   limit: 3, null: false

      t.boolean :active, null: false, default: true

      t.timestamp :notification_sent_at, limit: 3, null: true

      t.references :created_by, type: :integer, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, type: :integer, null: false, foreign_key: { to_table: :users }

      t.timestamps limit: 3, null: false

      t.index :active
    end
  end

  def create_admin_messages_groups_table
    create_table :admin_messages_groups, id: false do |t|
      t.references :admin_message, type: :integer, foreign_key: { to_table: :admin_messages }, index: false
      t.references :group, type: :integer, index: false
    end
    add_index :admin_messages_groups, [:admin_message_id]
    add_index :admin_messages_groups, [:group_id]
    add_foreign_key :admin_messages_groups, :groups
  end

  def create_admin_message_permission
    Permission.create_if_not_exists(
      name:        'admin.message',
      label:       'Admin Messages',
      description: 'Manage admin messages of your system.',
      preferences: { prio: 1425 },
    )
  end

  def create_admin_message_scheduler
    Scheduler.create_if_not_exists(
      name:          'Process admin messages.',
      method:        'AdminMessage.process',
      period:        1.minute,
      prio:          1,
      active:        true,
      last_run:      Time.zone.now,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
