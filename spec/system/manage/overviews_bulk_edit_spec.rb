# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Overviews > Bulk edit', type: :system do
  let(:agent_role) { Role.find_by(name: 'Agent') }
  let(:admin_role) { Role.find_by(name: 'Admin') }

  let!(:overview_one) do
    create(:overview, name: 'Bulk Overview One', role_ids: [agent_role.id], active: true)
  end

  let!(:overview_two) do
    create(:overview, name: 'Bulk Overview Two', role_ids: [agent_role.id], active: true)
  end

  let!(:folder) { create(:overview_folder, name: 'Bulk Folder') }
  let!(:nested) { create(:overview_folder, name: 'Nested Folder', parent: folder) }

  def select_overview(overview)
    find("tr[data-id='#{overview.id}'] td.table-checkbox").check('bulk', allow_label_click: true)
  end

  before do
    visit '/#manage/overviews'
  end

  it 'enables the bulk edit button and shows the selection count only once an overview is selected' do
    expect(page).to have_css('[data-type=bulk-edit].is-disabled', text: 'Edit selected')

    select_overview(overview_one)
    expect(page).to have_css('[data-type=bulk-edit]:not(.is-disabled)', text: 'Edit selected (1)')

    select_overview(overview_two)
    expect(page).to have_css('[data-type=bulk-edit]:not(.is-disabled)', text: 'Edit selected (2)')
  end

  it 'adds a role to the selected overviews while keeping their existing roles' do
    select_overview(overview_one)
    select_overview(overview_two)

    find('[data-type=bulk-edit]').click

    in_modal do
      check 'change_roles', allow_label_click: true

      expect(page).to have_text('The selected overviews currently use these roles')

      find("div[data-attribute-name='role_ids'] div.js-pool div[data-value='#{admin_role.id}']").click

      click_on 'Apply changes'
    end

    expect(overview_one.reload.role_ids).to contain_exactly(agent_role.id, admin_role.id)
    expect(overview_two.reload.role_ids).to contain_exactly(agent_role.id, admin_role.id)
  end

  it 'changes the active state of the selected overviews without touching other settings' do
    original_view = overview_one.view

    select_overview(overview_one)
    select_overview(overview_two)

    find('[data-type=bulk-edit]').click

    in_modal do
      check 'change_active', allow_label_click: true

      within('.overview-bulk-section[data-section="active"]') do
        select 'inactive', from: 'active'
      end

      click_on 'Apply changes'
    end

    expect(overview_one.reload).to have_attributes(active: false, view: original_view)
    expect(overview_two.reload).to have_attributes(active: false)
  end

  it 'moves the selected overviews into a folder' do
    select_overview(overview_one)
    select_overview(overview_two)

    find('[data-type=bulk-edit]').click

    in_modal do
      check 'change_folder', allow_label_click: true

      expect(page).to have_text('The selected overviews are currently located in: no folder (2/2)')

      within('.overview-bulk-section[data-section="folder"]') do
        expect(page).to have_select('folder_id', with_options: ['Bulk Folder', 'Bulk Folder / Nested Folder'])

        select 'Bulk Folder / Nested Folder', from: 'folder_id'
      end

      click_on 'Apply changes'
    end

    expect(overview_one.reload.folder).to eq(nested)
    expect(overview_two.reload.folder).to eq(nested)
  end

  context 'when the selected overviews are already in a folder' do
    let!(:overview_one) do
      create(:overview, name: 'Bulk Overview One', role_ids: [agent_role.id], folder: folder)
    end

    let!(:overview_two) do
      create(:overview, name: 'Bulk Overview Two', role_ids: [agent_role.id], folder: folder)
    end

    it 'moves them out of the folder to the top level' do
      select_overview(overview_one)
      select_overview(overview_two)

      find('[data-type=bulk-edit]').click

      in_modal do
        check 'change_folder', allow_label_click: true

        expect(page).to have_text('The selected overviews are currently located in: Bulk Folder (2/2)')

        click_on 'Apply changes'
      end

      expect(overview_one.reload.folder_id).to be_nil
      expect(overview_two.reload.folder_id).to be_nil
    end
  end

  context 'without any folder' do
    let!(:folder) { nil }
    let!(:nested) { nil }

    it 'refuses to apply an empty folder selection instead of silently clearing it' do
      select_overview(overview_one)

      find('[data-type=bulk-edit]').click

      in_modal disappears: false do
        check 'change_folder', allow_label_click: true

        click_on 'Apply changes'

        expect(page).to have_css('.modal-alerts-container', text: 'No folders are available yet.')
      end
    end
  end

  it 'does not change anything when no setting is enabled' do
    select_overview(overview_one)

    find('[data-type=bulk-edit]').click

    in_modal disappears: false do
      click_on 'Apply changes'

      expect(page).to have_css('.modal-alerts-container', text: 'Please enable at least one setting to change.')
    end
  end
end
