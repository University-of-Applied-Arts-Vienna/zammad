# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Monitoring', type: :request do
  let(:token) { Setting.get('monitoring_token') }

  describe 'Health check API not working when logged in as non-admin #5029' do
    let(:admin) { create(:admin) }
    let(:customer) { create(:customer) }

    context 'when admin', authenticated_as: :admin do
      it 'does return results via token' do
        get "/api/v1/monitoring/health_check?token=#{token}", as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'does return results without token' do
        get '/api/v1/monitoring/health_check', as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when customer', authenticated_as: :customer do
      it 'does return results via token' do
        get "/api/v1/monitoring/health_check?token=#{token}", as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'does not return results without token' do
        get '/api/v1/monitoring/health_check', as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/v1/monitoring/failed_emails' do
    let(:admin) { create(:admin) }
    let(:agent) { create(:agent) }

    before do
      create(:failed_email, channel: create(:email_channel, mail_server_user: 'support@example.com'))
    end

    context 'when admin', authenticated_as: :admin do
      it 'returns the failed emails', :aggregate_failures do
        get '/api/v1/monitoring/failed_emails', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['total_count']).to eq(1)
        expect(json_response['failed_emails'].first).to include('account' => 'support@example.com', 'subject' => 'some subject')
      end
    end

    context 'when agent', authenticated_as: :agent do
      it 'does not return results, not even via token' do
        get "/api/v1/monitoring/failed_emails?token=#{token}", as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
