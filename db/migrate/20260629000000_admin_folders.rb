# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AdminFolders < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    create_table :admin_folders, id: :integer do |t|
      t.column :name,          :string,  limit: 250, null: false
      t.column :target_model,  :string,  limit: 100, null: false
      t.column :parent_id,     :integer,             null: true
      t.column :prio,          :integer,             null: false
      t.column :active,        :boolean,             null: false, default: true
      t.integer :updated_by_id,                      null: false
      t.integer :created_by_id,                      null: false
      t.timestamps limit: 3, null: false
    end
    add_index :admin_folders, :name
    add_index :admin_folders, :target_model
    add_index :admin_folders, :parent_id
    add_foreign_key :admin_folders, :admin_folders, column: :parent_id
    add_foreign_key :admin_folders, :users, column: :created_by_id
    add_foreign_key :admin_folders, :users, column: :updated_by_id

    add_admin_folder_reference(:triggers)
    Trigger.reset_column_information

    add_admin_folder_reference(:core_workflows)
    CoreWorkflow.reset_column_information

    add_admin_folder_reference(:text_modules)
    TextModule.reset_column_information

    add_admin_folder_reference(:macros)
    Macro.reset_column_information

    add_admin_folder_reference(:jobs)
    Job.reset_column_information
  end

  private

  # The caller resets the column information of the affected model afterwards.
  def add_admin_folder_reference(table)
    add_column table, :admin_folder_id, :integer, null: true # rubocop:disable Zammad/ExistsResetColumnInformation
    add_index table, :admin_folder_id
    add_foreign_key table, :admin_folders, column: :admin_folder_id
  end
end
