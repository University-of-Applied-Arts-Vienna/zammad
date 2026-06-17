# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::Ticket::OverviewFolders, type: :graphql do
  context 'when fetching ticket overview folders' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query overviewFolders($ignoreUserConditions: Boolean!) {
          userCurrentTicketOverviewFolders(ignoreUserConditions: $ignoreUserConditions) {
            id
            internalId
            name
            prio
            parentId
            active
          }
        }
      QUERY
    end
    let(:variables) { { ignoreUserConditions: false } }

    let(:root)  { create(:overview_folder) }
    let(:child) { create(:overview_folder, parent: root) }

    before do
      create(:overview, role_ids: [Role.find_by(name: 'Agent').id], folder: child)
      gql.execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do
      it 'returns the folder and its ancestor chain' do
        names = gql.result.data.pluck('name')
        expect(names).to contain_exactly(root.name, child.name)
      end

      it 'exposes the parent relationship via internal IDs' do
        child_result = gql.result.data.find { |folder| folder['name'] == child.name }
        expect(child_result['parentId']).to eq(root.id)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
