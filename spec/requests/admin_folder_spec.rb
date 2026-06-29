# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Admin Folders', type: :request do
  let(:admin) { create(:admin) }
  let(:agent) { create(:agent) }

  describe 'request handling' do
    context 'without any admin permission' do
      before { authenticated_as(agent) }

      it 'does not allow listing' do
        get '/api/v1/admin_folders', as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not allow creation' do
        post '/api/v1/admin_folders', params: { name: 'Folder', target_model: 'Trigger' }, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with a matching admin permission' do
      before { authenticated_as(admin) }

      it 'creates a folder' do
        post '/api/v1/admin_folders', params: { name: 'Folder A', target_model: 'Trigger' }, as: :json

        aggregate_failures do
          expect(response).to have_http_status(:created)
          expect(json_response).to include('name' => 'Folder A', 'target_model' => 'Trigger')
        end
      end

      it 'rejects an unsupported target model' do
        post '/api/v1/admin_folders', params: { name: 'Folder', target_model: 'User' }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'creates a nested folder' do
        parent = create(:admin_folder)

        post '/api/v1/admin_folders', params: { name: 'Child', target_model: 'Trigger', parent_id: parent.id }, as: :json

        aggregate_failures do
          expect(response).to have_http_status(:created)
          expect(json_response).to include('parent_id' => parent.id)
        end
      end

      it 'rejects a cyclic parent assignment' do
        folder = create(:admin_folder)

        put "/api/v1/admin_folders/#{folder.id}", params: { name: folder.name, target_model: folder.target_model, parent_id: folder.id }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'updates the prio of folders' do
        folder1 = create(:admin_folder)
        folder2 = create(:admin_folder)

        post '/api/v1/admin_folders_prio', params: { prios: [[folder2.id, 1], [folder1.id, 2]] }, as: :json

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(folder2.reload.prio).to eq(1)
          expect(folder1.reload.prio).to eq(2)
        end
      end

      it 'destroys a folder' do
        folder = create(:admin_folder)

        delete "/api/v1/admin_folders/#{folder.id}", as: :json

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(AdminFolder).not_to exist(folder.id)
        end
      end

      it 'searches folders (used by the admin list)' do
        folder = create(:admin_folder, name: 'Searchable folder')

        post '/api/v1/admin_folders/search', params: { query: '', full: true }, as: :json

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(json_response['record_ids']).to include(folder.id)
        end
      end
    end

    context 'with a non-matching admin permission' do
      let(:trigger_admin) { create(:user, roles: [create(:role, permission_names: ['admin.trigger'])]) }

      before { authenticated_as(trigger_admin) }

      it 'allows managing folders of the permitted target model' do
        post '/api/v1/admin_folders', params: { name: 'Trigger folder', target_model: 'Trigger' }, as: :json

        expect(response).to have_http_status(:created)
      end

      it 'forbids creating folders of another target model' do
        post '/api/v1/admin_folders', params: { name: 'Macro folder', target_model: 'Macro' }, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'forbids deleting folders of another target model' do
        folder = create(:admin_folder, target_model: 'Macro')

        delete "/api/v1/admin_folders/#{folder.id}", as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'assigning objects to a folder' do
    let(:folder)  { create(:admin_folder) }
    let(:trigger) { create(:trigger) }

    before { authenticated_as(admin) }

    it 'moves a trigger into a folder' do
      put "/api/v1/triggers/#{trigger.id}", params: { name: trigger.name, admin_folder_id: folder.id }, as: :json

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(trigger.reload.admin_folder_id).to eq(folder.id)
      end
    end

    it 'moves a trigger back to the root level' do
      trigger.update!(admin_folder: folder)

      put "/api/v1/triggers/#{trigger.id}", params: { name: trigger.name, admin_folder_id: nil }, as: :json

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(trigger.reload.admin_folder_id).to be_nil
      end
    end
  end
end
