# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OverviewFolder, type: :model do
  subject(:folder) { create(:overview_folder) }

  describe 'validations' do
    it 'requires a name' do
      expect(build(:overview_folder, name: nil)).not_to be_valid
    end

    it 'cannot be its own parent' do
      folder.parent_id = folder.id
      expect(folder).not_to be_valid
    end

    it 'cannot be moved into one of its descendants' do
      child      = create(:overview_folder, parent: folder)
      grandchild = create(:overview_folder, parent: child)

      folder.parent = grandchild
      expect(folder).not_to be_valid
    end

    it 'allows a regular parent assignment' do
      parent = create(:overview_folder)
      folder.parent = parent
      expect(folder).to be_valid
    end
  end

  describe '#ancestors' do
    it 'returns the chain of parents starting with the direct parent' do
      root   = create(:overview_folder)
      middle = create(:overview_folder, parent: root)
      leaf   = create(:overview_folder, parent: middle)

      expect(leaf.ancestors).to eq([middle, root])
    end
  end

  describe '#descendants' do
    it 'returns all transitive children' do
      root   = create(:overview_folder)
      middle = create(:overview_folder, parent: root)
      leaf   = create(:overview_folder, parent: middle)

      expect(root.descendants).to contain_exactly(middle, leaf)
    end
  end

  describe 'prioritization' do
    it 'auto-assigns an increasing prio' do
      first  = create(:overview_folder, prio: nil)
      second = create(:overview_folder, prio: nil)

      expect(second.prio).to be > first.prio
    end
  end

  describe 'dependent overviews' do
    it 'nullifies the folder reference on its overviews when destroyed' do
      overview = create(:overview, folder: folder)

      folder.destroy

      expect(overview.reload.folder_id).to be_nil
    end

    it 'destroys child folders' do
      child = create(:overview_folder, parent: folder)

      folder.destroy

      expect { child.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
