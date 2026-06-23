# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::CurrentAdminMessages, authenticated_as: :user, type: :graphql do
  let(:group) { create(:group) }
  let(:user)  { create(:agent, groups: [group]) }

  let(:query) do
    <<~QUERY
      query currentAdminMessages {
        currentAdminMessages {
          id
          message
          endAt
        }
      }
    QUERY
  end

  let!(:live_all)   { create(:admin_message, :live, message: 'For everyone') }
  let!(:live_group) { create(:admin_message, :live, groups: [group]) }

  before do
    create(:admin_message, :upcoming)
    create(:admin_message, :expired)
    gql.execute(query)
  end

  context 'when authenticated as an agent with group access' do
    it 'returns live messages targeted at all users and at the agent groups' do
      expect(gql.result.data.pluck('id')).to contain_exactly(gql.id(live_all), gql.id(live_group))
    end
  end

  context 'when authenticated as a customer' do
    let(:user) { create(:customer) }

    it 'returns only messages targeted at all users' do
      expect(gql.result.data.pluck('id')).to contain_exactly(gql.id(live_all))
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
