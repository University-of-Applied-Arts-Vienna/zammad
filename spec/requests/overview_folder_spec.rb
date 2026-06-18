# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Overview Folders', type: :request do
  let(:admin) { create(:admin) }
  let(:agent) { create(:agent) }

  describe 'request handling' do
    context 'without admin.overview permission' do
      before { authenticated_as(agent) }

      it 'does not allow listing' do
        get '/api/v1/overview_folders', as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not allow creation' do
        post '/api/v1/overview_folders', params: { name: 'Folder' }, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with admin.overview permission' do
      before { authenticated_as(admin) }

      it 'creates a folder' do
        post '/api/v1/overview_folders', params: { name: 'Folder A' }, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response).to include('name' => 'Folder A')
      end

      it 'creates a nested folder' do
        parent = create(:overview_folder)

        post '/api/v1/overview_folders', params: { name: 'Child', parent_id: parent.id }, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response).to include('parent_id' => parent.id)
      end

      it 'rejects a cyclic parent assignment' do
        folder = create(:overview_folder)

        put "/api/v1/overview_folders/#{folder.id}", params: { name: folder.name, parent_id: folder.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'updates the prio of folders' do
        folder1 = create(:overview_folder)
        folder2 = create(:overview_folder)

        post '/api/v1/overview_folders_prio', params: { prios: [[folder2.id, 1], [folder1.id, 2]] }, as: :json

        expect(response).to have_http_status(:ok)
        expect(folder2.reload.prio).to eq(1)
        expect(folder1.reload.prio).to eq(2)
      end

      it 'destroys a folder' do
        folder = create(:overview_folder)

        delete "/api/v1/overview_folders/#{folder.id}", as: :json

        expect(response).to have_http_status(:ok)
        expect(OverviewFolder).not_to exist(folder.id)
      end

      it 'searches folders (used by the admin overview list)' do
        folder = create(:overview_folder, name: 'Searchable folder')

        post '/api/v1/overview_folders/search', params: { query: '', full: true }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['record_ids']).to include(folder.id)
      end

      it 'filters folders by query' do
        match = create(:overview_folder, name: 'Sales')
        create(:overview_folder, name: 'Support')

        post '/api/v1/overview_folders/search', params: { query: 'Sales', full: true }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['record_ids']).to eq([match.id])
      end
    end
  end

  describe 'assigning overviews to a folder' do
    let(:folder)   { create(:overview_folder) }
    let(:overview) { create(:overview) }

    before { authenticated_as(admin) }

    it 'moves an overview into a folder' do
      put "/api/v1/overviews/#{overview.id}", params: { name: overview.name, folder_id: folder.id, roles: ['Agent'] }, as: :json

      expect(response).to have_http_status(:ok)
      expect(overview.reload.folder_id).to eq(folder.id)
    end

    it 'moves an overview back to the root level' do
      overview.update!(folder: folder)

      put "/api/v1/overviews/#{overview.id}", params: { name: overview.name, folder_id: nil, roles: ['Agent'] }, as: :json

      expect(response).to have_http_status(:ok)
      expect(overview.reload.folder_id).to be_nil
    end
  end
end
