# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Text Modules > Bulk edit', type: :system do
  let!(:folder)       { create(:admin_folder, target_model: 'TextModule', name: 'Sales') }
  let!(:other_folder) { create(:admin_folder, target_model: 'TextModule', name: 'Support') }
  let!(:nested)       { create(:admin_folder, target_model: 'TextModule', name: 'Escalations', parent: folder) }

  # Overridden by the examples which need the text modules to start out in a folder.
  let(:initial_folder) { nil }

  let!(:text_module_one) { create(:text_module, name: 'Bulk TM One', active: true, admin_folder: initial_folder) }
  let!(:text_module_two) { create(:text_module, name: 'Bulk TM Two', active: true, admin_folder: initial_folder) }

  def select_text_module(text_module)
    find("tr[data-id='#{text_module.id}'] td.table-checkbox").check('bulk', allow_label_click: true)
  end

  def bulk_move_to(label)
    select_text_module(text_module_one)
    select_text_module(text_module_two)

    find('[data-type=admin-bulk-edit]').click

    in_modal do
      check 'change_folder', allow_label_click: true

      within('.overview-bulk-section[data-section="folder"]') do
        select label, from: 'admin_folder_id'
      end

      click_on 'Apply changes'
    end
  end

  before do
    visit '/#manage/text_modules'
  end

  it 'moves the selected text modules into a folder' do
    bulk_move_to('Sales')

    expect(text_module_one.reload).to have_attributes(admin_folder_id: folder.id, active: true)
    expect(text_module_two.reload).to have_attributes(admin_folder_id: folder.id, active: true)
  end

  it 'offers nested folders with their full path and shows the current assignment' do
    select_text_module(text_module_one)

    find('[data-type=admin-bulk-edit]').click

    in_modal disappears: false do
      check 'change_folder', allow_label_click: true

      expect(page).to have_text('The selected items are currently located in: no folder (1/1)')

      within('.overview-bulk-section[data-section="folder"]') do
        expect(page).to have_select('admin_folder_id', with_options: ['Sales', 'Sales / Escalations', 'Support'])
      end
    end
  end

  it 'moves the selected text modules into a nested folder' do
    bulk_move_to('Sales / Escalations')

    expect(text_module_one.reload.admin_folder_id).to eq(nested.id)
    expect(text_module_two.reload.admin_folder_id).to eq(nested.id)
  end

  context 'when the text modules are already in a folder' do
    let(:initial_folder) { folder }

    it 'moves them into a different folder' do
      bulk_move_to('Support')

      expect(text_module_one.reload.admin_folder_id).to eq(other_folder.id)
      expect(text_module_two.reload.admin_folder_id).to eq(other_folder.id)
    end

    it 'moves them out to the top level' do
      select_text_module(text_module_one)
      select_text_module(text_module_two)

      find('[data-type=admin-bulk-edit]').click

      in_modal do
        check 'change_folder', allow_label_click: true

        expect(page).to have_text('The selected items are currently located in: Sales (2/2)')

        click_on 'Apply changes'
      end

      expect(text_module_one.reload.admin_folder_id).to be_nil
      expect(text_module_two.reload.admin_folder_id).to be_nil
    end
  end

  context 'with text modules spread over several folders' do
    let!(:in_sales)   { create_list(:text_module, 3, admin_folder: folder) }
    let!(:in_support) { create_list(:text_module, 3, admin_folder: other_folder) }

    it 'moves everything selected via the select-all checkbox into one folder' do
      expect(TextModule.where(admin_folder_id: [folder.id, other_folder.id]).count).to eq(in_sales.count + in_support.count)

      # "Select all" only ticks the rendered rows, so wait for the complete list
      #   (the seeded text modules included) before using it.
      expect(page).to have_css('tbody tr[data-id]', count: TextModule.count)

      find('th.table-checkbox').check('bulk_all', allow_label_click: true)

      expect(page).to have_css('[data-type=admin-bulk-edit]:not(.is-disabled)')

      find('[data-type=admin-bulk-edit]').click

      in_modal do
        check 'change_folder', allow_label_click: true

        within('.overview-bulk-section[data-section="folder"]') do
          select 'Sales / Escalations', from: 'admin_folder_id'
        end

        click_on 'Apply changes'
      end

      expect(TextModule.where(admin_folder_id: nested.id).count).to eq(TextModule.count)
    end
  end

  context 'without any folder' do
    let!(:folder)       { nil }
    let!(:other_folder) { nil }
    let!(:nested)       { nil }

    it 'refuses to apply an empty folder selection instead of silently clearing it' do
      select_text_module(text_module_one)

      find('[data-type=admin-bulk-edit]').click

      in_modal disappears: false do
        check 'change_folder', allow_label_click: true

        click_on 'Apply changes'

        expect(page).to have_css('.modal-alerts-container', text: 'No folders are available yet.')
      end
    end
  end
end
