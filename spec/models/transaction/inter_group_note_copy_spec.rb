# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Transaction::InterGroupNoteCopy, type: :model do
  let(:requesting_group) { create(:group) }
  let(:requested_group)  { create(:group) }
  let(:agent)            { create(:agent, groups: [requested_group]) }
  let(:message_id)       { "<#{SecureRandom.uuid}@zammad.example.com>" }
  let(:setting_active)   { true }

  # The requesting group emailed the requested group's address from its ticket, the
  # requested group got its own ticket with the imported copy of that mail.
  let(:origin_ticket) { create(:ticket, group: requesting_group, state_name: 'pending reminder', pending_time: 1.day.from_now) }
  let(:ticket)        { create(:ticket, group: requested_group) }

  let(:outgoing_article_trait) { :outbound_email }
  let!(:imported_article) { create(:ticket_article, :inbound_email, ticket:, message_id:) }

  let(:note) { create(:ticket_article, :outbound_note, ticket:, body: 'the answer', created_by_id: agent.id) }

  let(:item) do
    {
      object:     'Ticket',
      type:       'update',
      object_id:  ticket.id,
      article_id: note.id,
      user_id:    agent.id,
    }
  end

  def perform(item)
    described_class.new(item).perform
  end

  def copies
    origin_ticket.articles.reload.select { |article| article.preferences[:inter_group_note_copy].present? }
  end

  before do
    create(:ticket_article, outgoing_article_trait, ticket: origin_ticket, message_id:, created_at: 1.hour.ago)

    Setting.set('postmaster_follow_up_new_ticket_for_different_group', setting_active)
  end

  describe '.origin_ticket' do
    it 'returns the ticket the request was sent from' do
      expect(described_class.origin_ticket(ticket)).to eq(origin_ticket)
    end

    it 'returns nothing for the ticket the request was sent from' do
      expect(described_class.origin_ticket(origin_ticket)).to be_nil
    end

    context 'when the other ticket belongs to the same group' do
      let(:origin_ticket) { create(:ticket, group: requested_group) }

      it 'returns nothing' do
        expect(described_class.origin_ticket(ticket)).to be_nil
      end
    end

    context 'when the matching article of the other ticket is not an outgoing email' do
      let(:outgoing_article_trait) { :inbound_email }

      it 'returns nothing' do
        expect(described_class.origin_ticket(ticket)).to be_nil
      end
    end
  end

  context 'when a public note is added to the requested ticket' do
    it 'copies the note as an internal note into the origin ticket' do
      perform(item)

      expect(copies.first).to have_attributes(
        body:          end_with('the answer'),
        internal:      true,
        type:          Ticket::Article::Type.lookup(name: 'note'),
        created_by_id: agent.id,
        preferences:   include(inter_group_note_copy: include(ticket_id: ticket.id, article_id: note.id)),
      )
    end

    it 'states where the note comes from' do
      perform(item)

      expect(copies.first.body).to start_with("↪ #{requested_group.fullname} · #{agent.fullname} · #{Setting.get('ticket_hook')}#{ticket.number}\n\n")
    end

    context 'with an html note' do
      let(:requested_group) { create(:group, name: 'Dep <2>') }
      let(:note)            { create(:ticket_article, :outbound_note, ticket:, content_type: 'text/html', body: '<p>the answer</p>', created_by_id: agent.id) }

      it 'prepends an escaped source line' do
        perform(item)

        expect(copies.first.body).to start_with("<p><strong>↪ Dep &lt;2&gt; · #{agent.fullname}").and end_with('<p>the answer</p>')
      end
    end

    it 'reopens the origin ticket' do
      expect { perform(item) }.to change { origin_ticket.reload.state.name }.to('open')
    end

    it 'links both tickets' do
      perform(item)

      expect(Link.list(link_object: 'Ticket', link_object_value: ticket.id))
        .to include(include('link_object' => 'Ticket', 'link_object_value' => origin_ticket.id))
    end

    it 'links both tickets only once' do
      perform(item)

      expect { perform(item.merge(article_id: create(:ticket_article, :outbound_note, ticket:).id)) }
        .not_to change(Link, :count)
    end

    context 'with an attachment' do
      let(:note) { create(:ticket_article, :outbound_note, :with_attachment, ticket:) }

      it 'copies the attachment' do
        perform(item)

        expect(copies.first.attachments.map(&:filename)).to eq(['hello_world.txt'])
      end
    end

    context 'when the origin ticket is still new' do
      let(:origin_ticket) { create(:ticket, group: requesting_group, state_name: 'new') }

      it 'keeps the state' do
        expect { perform(item) }.not_to change { origin_ticket.reload.state.name }
      end
    end

    context 'when the origin ticket was merged' do
      let(:target_ticket) { create(:ticket, group: requesting_group) }

      before { origin_ticket.merge_to(ticket_id: target_ticket.id, user_id: 1) }

      it 'copies the note into the merge target' do
        expect { perform(item) }.to change { target_ticket.articles.reload.count }.by(1)
      end
    end

    context 'when the setting is disabled' do
      let(:setting_active) { false }

      it 'does not copy the note' do
        expect { perform(item) }.not_to change { origin_ticket.articles.reload.count }
      end
    end
  end

  context 'when an internal note is added to the requested ticket' do
    let(:note) { create(:ticket_article, :internal_note, ticket:) }

    it 'does not copy the note' do
      expect { perform(item) }.not_to change { origin_ticket.articles.reload.count }
    end
  end

  context 'when an email is added to the requested ticket' do
    let(:note) { create(:ticket_article, :outbound_email, ticket:) }

    it 'does not copy the article' do
      expect { perform(item) }.not_to change { origin_ticket.articles.reload.count }
    end
  end

  context 'when a public note is added to the origin ticket' do
    let(:note) { create(:ticket_article, :outbound_note, ticket: origin_ticket) }
    let(:item) { { object: 'Ticket', type: 'update', object_id: origin_ticket.id, article_id: note.id } }

    it 'does not copy the note to the requested ticket' do
      expect { perform(item) }.not_to change { ticket.articles.reload.count }
    end
  end

  context 'when the requested ticket gets created' do
    let(:item) { { object: 'Ticket', type: 'create', object_id: ticket.id, article_id: imported_article.id } }

    it 'links both tickets' do
      expect { perform(item) }.to change(Link, :count).by(1)
    end

    it 'confirms the created ticket with an internal note in the origin ticket' do
      perform(item)

      expect(origin_ticket.articles.reload.last).to have_attributes(
        body:        "<p>✓ #{requested_group.fullname}: Ticket #{ticket.number} created!</p>",
        internal:    true,
        type:        Ticket::Article::Type.lookup(name: 'note'),
        sender:      Ticket::Article::Sender.lookup(name: 'System'),
        preferences: include(inter_group_ticket_created: include(ticket_id: ticket.id)),
      )
    end

    it 'does not change the state of the origin ticket' do
      expect { perform(item) }.not_to change { origin_ticket.reload.state.name }
    end

    it 'confirms the created ticket in the system language' do
      Setting.set('locale_default', 'de-de')

      perform(item)

      expect(origin_ticket.articles.reload.last.body).to include("Ticket #{ticket.number} erstellt!")
    end

    it 'confirms the created ticket only once' do
      perform(item)

      expect { perform(item) }.not_to change { origin_ticket.articles.reload.count }
    end

    it 'does not copy the imported article' do
      perform(item)

      expect(copies).to be_empty
    end
  end

  context 'when running through the transaction dispatcher', performs_jobs: true do
    it 'confirms the created ticket and copies the note' do
      note
      TransactionDispatcher.commit
      perform_enqueued_jobs(only: TransactionJob)

      expect(origin_ticket.articles.reload.map(&:preferences)).to include(
        include(:inter_group_ticket_created),
        include(:inter_group_note_copy),
      )
    end
  end
end
