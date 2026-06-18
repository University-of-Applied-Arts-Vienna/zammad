# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UserOverviewFolderSortings < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    create_table :user_overview_folder_sortings, id: :integer do |t|
      t.column :user_id,            :integer, null: false
      t.column :overview_folder_id, :integer, null: false
      t.column :prio,               :integer, null: false
      t.integer :updated_by_id,               null: false
      t.integer :created_by_id,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :user_overview_folder_sortings, :user_id
    add_index :user_overview_folder_sortings, :overview_folder_id
    add_foreign_key :user_overview_folder_sortings, :users, column: :created_by_id
    add_foreign_key :user_overview_folder_sortings, :users, column: :updated_by_id
    add_foreign_key :user_overview_folder_sortings, :users, column: :user_id
    add_foreign_key :user_overview_folder_sortings, :overview_folders, column: :overview_folder_id
  end
end
