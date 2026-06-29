# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AdminFolder, type: :model do
  subject(:folder) { create(:admin_folder) }

  describe 'validations' do
    it 'requires a name' do
      expect(build(:admin_folder, name: nil)).not_to be_valid
    end

    it 'requires a target model' do
      expect(build(:admin_folder, target_model: nil)).not_to be_valid
    end

    it 'rejects an unsupported target model' do
      expect(build(:admin_folder, target_model: 'User')).not_to be_valid
    end

    it 'cannot be its own parent' do
      folder.parent_id = folder.id
      expect(folder).not_to be_valid
    end

    it 'cannot be moved into one of its descendants' do
      child      = create(:admin_folder, parent: folder)
      grandchild = create(:admin_folder, parent: child)

      folder.parent = grandchild
      expect(folder).not_to be_valid
    end

    it 'allows a regular parent assignment of the same target model' do
      parent = create(:admin_folder)
      folder.parent = parent
      expect(folder).to be_valid
    end

    it 'rejects a parent of a different target model' do
      parent = create(:admin_folder, target_model: 'Macro')
      folder.parent = parent
      expect(folder).not_to be_valid
    end
  end

  describe '#required_permission' do
    it 'maps the target model to its admin permission' do
      expect(build(:admin_folder, target_model: 'Job').required_permission).to eq('admin.scheduler')
    end
  end

  describe '#ancestors' do
    it 'returns the chain of parents starting with the direct parent' do
      root   = create(:admin_folder)
      middle = create(:admin_folder, parent: root)
      leaf   = create(:admin_folder, parent: middle)

      expect(leaf.ancestors).to eq([middle, root])
    end
  end

  describe '#descendants' do
    it 'returns all transitive children' do
      root   = create(:admin_folder)
      middle = create(:admin_folder, parent: root)
      leaf   = create(:admin_folder, parent: middle)

      expect(root.descendants).to contain_exactly(middle, leaf)
    end
  end

  describe 'prioritization' do
    it 'auto-assigns an increasing prio' do
      first  = create(:admin_folder, prio: nil)
      second = create(:admin_folder, prio: nil)

      expect(second.prio).to be > first.prio
    end
  end

  describe 'dependent objects' do
    it 'nullifies the folder reference on its objects when destroyed' do
      trigger = create(:trigger, admin_folder: folder)

      folder.destroy

      expect(trigger.reload.admin_folder_id).to be_nil
    end

    it 'destroys child folders' do
      child = create(:admin_folder, parent: folder)

      folder.destroy

      expect { child.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
