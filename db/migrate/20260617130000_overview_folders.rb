# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OverviewFolders < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    create_table :overview_folders do |t|
      t.column :name,          :string,  limit: 250, null: false
      t.column :parent_id,     :integer,             null: true
      t.column :prio,          :integer,             null: false
      t.column :active,        :boolean,             null: false, default: true
      t.integer :updated_by_id,                      null: false
      t.integer :created_by_id,                      null: false
      t.timestamps limit: 3, null: false
    end
    add_index :overview_folders, :name
    add_index :overview_folders, :parent_id
    add_foreign_key :overview_folders, :overview_folders, column: :parent_id
    add_foreign_key :overview_folders, :users, column: :created_by_id
    add_foreign_key :overview_folders, :users, column: :updated_by_id

    add_column :overviews, :folder_id, :integer, null: true
    add_index :overviews, :folder_id
    add_foreign_key :overviews, :overview_folders, column: :folder_id

    Overview.reset_column_information
  end
end
