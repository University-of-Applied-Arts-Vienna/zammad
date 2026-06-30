# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Trigger > Bulk edit', type: :system do
  let!(:folder) { create(:admin_folder, target_model: 'Trigger', name: 'Sales') }

  let!(:trigger_one) { create(:trigger, name: 'Bulk Trigger One', active: true) }
  let!(:trigger_two) { create(:trigger, name: 'Bulk Trigger Two', active: true) }

  def select_trigger(trigger)
    find("tr[data-id='#{trigger.id}'] td.table-checkbox").check('bulk', allow_label_click: true)
  end

  before do
    visit '/#manage/trigger'
  end

  it 'enables the bulk edit button and shows the selection count only once a trigger is selected' do
    expect(page).to have_css('[data-type=admin-bulk-edit].is-disabled', text: 'Edit selected')

    select_trigger(trigger_one)
    expect(page).to have_css('[data-type=admin-bulk-edit]:not(.is-disabled)', text: 'Edit selected (1)')

    select_trigger(trigger_two)
    expect(page).to have_css('[data-type=admin-bulk-edit]:not(.is-disabled)', text: 'Edit selected (2)')
  end

  it 'moves the selected triggers into a folder' do
    select_trigger(trigger_one)
    select_trigger(trigger_two)

    find('[data-type=admin-bulk-edit]').click

    in_modal do
      check 'change_folder', allow_label_click: true

      within('.overview-bulk-section[data-section="folder"]') do
        select 'Sales', from: 'admin_folder_id'
      end

      click_on 'Apply changes'
    end

    expect(trigger_one.reload.admin_folder_id).to eq(folder.id)
    expect(trigger_two.reload.admin_folder_id).to eq(folder.id)
  end

  it 'changes the active state of the selected triggers' do
    select_trigger(trigger_one)
    select_trigger(trigger_two)

    find('[data-type=admin-bulk-edit]').click

    in_modal do
      check 'change_active', allow_label_click: true

      within('.overview-bulk-section[data-section="active"]') do
        select 'inactive', from: 'active'
      end

      click_on 'Apply changes'
    end

    expect(trigger_one.reload).to have_attributes(active: false)
    expect(trigger_two.reload).to have_attributes(active: false)
  end

  it 'does not change anything when no setting is enabled' do
    select_trigger(trigger_one)

    find('[data-type=admin-bulk-edit]').click

    in_modal disappears: false do
      click_on 'Apply changes'

      expect(page).to have_css('.modal-alerts-container', text: 'Please enable at least one setting to change.')
    end
  end
end
