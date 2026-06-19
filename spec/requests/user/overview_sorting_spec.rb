# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User Overview sorting', authenticated_as: :user, type: :request do
  let(:user)             { create(:agent) }
  let(:overview)         { Overview.first }
  let(:folder)           { create(:overview_folder) }
  let(:overview_sorting) { create(:user_overview_sorting, overview:, user:) }

  before do
    overview.update!(folder:)
  end

  describe 'GET /user_overview_sortings' do
    it 'returns overviews, folders and their sortings', aggregate_failures: true do
      overview_sorting

      get '/api/v1/user_overview_sortings'

      expect(json_response)
        .to include(
          'overviews'         => include(include('id' => overview.id)),
          'overview_sortings' => include(include('id' => overview_sorting.id)),
          'folders'           => include(include('id' => folder.id)),
        )
    end
  end

  describe 'POST /user_overview_sortings_prio' do
    it 'stores the personal overview and folder order', aggregate_failures: true do
      post '/api/v1/user_overview_sortings_prio',
           params: { entries: [{ type: 'OverviewFolder', id: folder.id }, { type: 'Overview', id: overview.id }] }

      expect(response).to have_http_status(:ok)
      expect(User::OverviewFolderSorting.find_by(user:, overview_folder: folder).prio)
        .to be < User::OverviewSorting.find_by(user:, overview:).prio
    end

    it 'ignores entries the user is not allowed to order' do
      post '/api/v1/user_overview_sortings_prio',
           params: { entries: [{ type: 'OverviewFolder', id: 0 }, { type: 'Overview', id: overview.id }] }

      expect(User::OverviewSorting.where(user:).count).to eq(1)
    end

    it 'triggers subscription' do
      allow(Gql::Subscriptions::User::Current::OverviewOrderingUpdates).to receive(:trigger_by)

      post '/api/v1/user_overview_sortings_prio',
           params: { entries: [{ type: 'Overview', id: overview.id }] }

      expect(Gql::Subscriptions::User::Current::OverviewOrderingUpdates)
        .to have_received(:trigger_by).with(user)
    end

    it 'clears the personal order on an explicit reset' do
      create(:user_overview_sorting, overview:, user:)

      post '/api/v1/user_overview_sortings_prio', params: { reset: true }

      expect(User::OverviewSorting.where(user:)).to be_empty
    end

    it 'keeps the existing order when the payload is empty' do
      sorting = create(:user_overview_sorting, overview:, user:)

      post '/api/v1/user_overview_sortings_prio', params: { entries: [] }

      expect(User::OverviewSorting.where(user:)).to contain_exactly(sorting)
    end

    it 'accepts the legacy overview-only payload' do
      post '/api/v1/user_overview_sortings_prio', params: { prios: [[overview.id, 1]] }

      expect(User::OverviewSorting.find_by(user:, overview:)).to be_present
    end
  end

  describe 'DELETE /user_overview_sortings/:id' do
    it 'deletes given sorting' do
      expect { delete "/api/v1/user_overview_sortings/#{overview_sorting.id}" }
        .to change { User::OverviewSorting.exists? overview_sorting.id }
        .to false
    end

    it 'triggers subscription' do
      allow(Gql::Subscriptions::User::Current::OverviewOrderingUpdates).to receive(:trigger_by)

      delete "/api/v1/user_overview_sortings/#{overview_sorting.id}"

      expect(Gql::Subscriptions::User::Current::OverviewOrderingUpdates)
        .to have_received(:trigger_by).with(user)
    end
  end
end
