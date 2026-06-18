# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::OverviewFolderSorting, type: :model do
  let(:user)   { create(:agent) }
  let(:folder) { create(:overview_folder) }

  it 'belongs to a user and a folder' do
    sorting = create(:user_overview_folder_sorting, user:, overview_folder: folder, prio: 1)

    expect(sorting).to have_attributes(user:, overview_folder: folder, prio: 1)
  end

  it 'is destroyed together with its folder' do
    sorting = create(:user_overview_folder_sorting, user:, overview_folder: folder)

    folder.destroy

    expect { sorting.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'orders by prio via the default scope' do
    second = create(:user_overview_folder_sorting, user:, overview_folder: create(:overview_folder), prio: 2)
    first  = create(:user_overview_folder_sorting, user:, overview_folder: create(:overview_folder), prio: 1)

    expect(described_class.where(user:).to_a).to eq([first, second])
  end
end
