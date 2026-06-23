# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AdminMessage', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  let(:create_params) do
    {
      message:  'Scheduled maintenance tonight.',
      start_at: Time.current,
      end_at:   1.day.from_now,
      active:   true,
    }
  end

  describe '#index' do
    it 'returns the list of admin messages' do
      create(:admin_message, message: 'Message A')

      get '/api/v1/admin_messages', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(include('message' => 'Message A'))
    end

    context 'when the user is not an admin' do
      let(:user) { create(:agent) }

      it 'is forbidden' do
        get '/api/v1/admin_messages', as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#create' do
    it 'creates a new admin message' do
      post '/api/v1/admin_messages', params: create_params, as: :json

      expect(response).to have_http_status(:created)
      expect(json_response).to include('message' => 'Scheduled maintenance tonight.')
    end

    it 'rejects an end that is not after the start' do
      post '/api/v1/admin_messages', params: create_params.merge(start_at: 1.day.from_now, end_at: Time.current), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe '#update' do
    it 'updates an existing admin message' do
      admin_message = create(:admin_message)

      put "/api/v1/admin_messages/#{admin_message.id}", params: { message: 'Updated message' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('message' => 'Updated message')
    end
  end

  describe '#destroy' do
    it 'deletes an admin message' do
      admin_message = create(:admin_message)

      delete "/api/v1/admin_messages/#{admin_message.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect { admin_message.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#current' do
    let(:user) { create(:agent) }

    it 'returns only the messages currently shown to the requesting user' do
      live = create(:admin_message, :live, message: 'Visible')
      create(:admin_message, :upcoming, message: 'Hidden')

      get '/api/v1/admin_messages/current', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(live.id)
    end

    context 'with a group-targeted message and a customer' do
      let(:group) { create(:group) }
      let(:user)  { create(:customer) }

      it 'is hidden from users without access to the group' do
        create(:admin_message, :live, groups: [group])

        get '/api/v1/admin_messages/current', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_empty
      end
    end
  end
end
