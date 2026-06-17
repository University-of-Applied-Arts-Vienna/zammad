# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::Overview::Folder::List do
  subject(:service) { described_class.with_current_user(agent) }

  let(:agent) { create(:agent) }

  let(:root)    { create(:overview_folder) }
  let(:child)   { create(:overview_folder, parent: root) }
  let(:sibling) { create(:overview_folder) }

  describe '#execute' do
    context 'when a visible overview lives in a (nested) folder' do
      before do
        create(:overview, role_ids: [Role.find_by(name: 'Agent').id], folder: child)
      end

      it 'returns the folder and its ancestor chain' do
        expect(service.execute(ignore_user_conditions: false)).to contain_exactly(root, child)
      end

      it 'prunes folders without any visible overview' do
        expect(service.execute(ignore_user_conditions: false)).not_to include(sibling)
      end
    end

    context 'when a folder only contains an overview the user may not use' do
      before do
        create(:overview, role_ids: [Role.find_by(name: 'Admin').id], folder: sibling)
      end

      it 'prunes the folder' do
        expect(service.execute(ignore_user_conditions: false)).not_to include(sibling)
      end
    end

    context 'when an inactive folder contains a visible overview' do
      before do
        root.update!(active: false)
        create(:overview, role_ids: [Role.find_by(name: 'Agent').id], folder: root)
      end

      it 'does not return the inactive folder' do
        expect(service.execute(ignore_user_conditions: false)).not_to include(root)
      end
    end

    context 'when no overview is assigned to any folder' do
      it 'returns an empty result' do
        expect(service.execute(ignore_user_conditions: false)).to be_empty
      end
    end
  end
end
