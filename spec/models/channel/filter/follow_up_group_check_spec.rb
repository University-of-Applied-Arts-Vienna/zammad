# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::FollowUpGroupCheck, type: :channel_filter do
  let(:group_a)        { create(:group) }
  let(:group_b)        { create(:group) }
  let(:ticket)         { create(:ticket, group: group_a) }
  let(:channel)        { create(:channel, group_id: group_b.id) }
  let(:setting_active) { true }

  let(:mail_hash) do
    {
      'x-zammad-ticket-id': ticket.id,
      subject:              "Re: [Ticket##{ticket.number}] some subject",
    }
  end

  before do
    Setting.set('postmaster_follow_up_new_ticket_for_different_group', setting_active)
  end

  context 'when the setting is enabled' do
    context 'when the follow-up belongs to a different group than the receiving channel' do
      it 'drops the follow-up association so a new ticket gets created' do
        filter(mail_hash, channel:)

        expect(mail_hash).to include('x-zammad-ticket-id': nil, 'x-zammad-ticket-number': nil)
      end

      it 'cleans the ticket hook from the subject' do
        filter(mail_hash, channel:)

        expect(mail_hash[:subject]).not_to include("[Ticket##{ticket.number}]")
      end
    end

    context 'when the mail references a ticket of the receiving group' do
      let(:origin_ticket) { create(:ticket, group: group_b) }
      let(:message_id)    { "<#{SecureRandom.uuid}@zammad.example.com>" }
      let(:mail_hash) do
        {
          'x-zammad-ticket-id': ticket.id,
          subject:              "Re: [Ticket##{ticket.number}] some subject",
          'in-reply-to':        message_id,
          references:           "<unknown@example.com> #{message_id}",
        }
      end

      before do
        # The mail the receiving group sent from its ticket, and the copy the
        # answering group imported (newer, so it is the newest article for the id).
        create(:ticket_article, ticket: origin_ticket, message_id:, created_at: 1.hour.ago)
        create(:ticket_article, ticket:, message_id:)
      end

      it 'threads the mail into the referenced ticket' do
        filter(mail_hash, channel:)

        expect(mail_hash).to include('x-zammad-ticket-id': origin_ticket.id)
      end

      it 'cleans the foreign ticket hook from the subject' do
        filter(mail_hash, channel:)

        expect(mail_hash[:subject]).not_to include("[Ticket##{ticket.number}]")
      end

      it 'drops a follow-up owner which was determined for the foreign ticket' do
        mail_hash[:'x-zammad-ticket-followup-owner'] = 'admin'

        filter(mail_hash, channel:)

        expect(mail_hash).not_to include(:'x-zammad-ticket-followup-owner')
      end

      context 'when the referenced ticket is closed and its group creates new tickets for follow-ups' do
        let(:group_b)       { create(:group, follow_up_possible: 'new_ticket') }
        let(:origin_ticket) { create(:ticket, group: group_b, state_name: 'closed') }

        it 'drops the follow-up association so a new ticket gets created' do
          filter(mail_hash, channel:)

          expect(mail_hash).to include('x-zammad-ticket-id': nil)
        end
      end

      context 'when the referenced ticket was merged' do
        let(:target_ticket) { create(:ticket, group: group_b) }

        before { origin_ticket.merge_to(ticket_id: target_ticket.id, user_id: 1) }

        it 'threads the mail into the merge target' do
          filter(mail_hash, channel:)

          expect(mail_hash).to include('x-zammad-ticket-id': target_ticket.id)
        end
      end
    end

    context 'when the mail only references tickets of other groups' do
      let(:mail_hash) do
        {
          'x-zammad-ticket-id': ticket.id,
          references:           ticket_article.message_id,
        }
      end
      let(:ticket_article) { create(:ticket_article, ticket:, message_id: "<#{SecureRandom.uuid}@zammad.example.com>") }

      it 'drops the follow-up association so a new ticket gets created' do
        filter(mail_hash, channel:)

        expect(mail_hash).to include('x-zammad-ticket-id': nil)
      end
    end

    context 'when the follow-up belongs to the receiving channel group' do
      let(:channel) { create(:channel, group_id: group_a.id) }

      it 'keeps the follow-up association' do
        filter(mail_hash, channel:)

        expect(mail_hash).to include('x-zammad-ticket-id': ticket.id)
      end
    end

    context 'when the receiving group is resolved via the To address' do
      let(:channel)       { create(:channel, group_id: nil) }
      let(:other_channel) { create(:channel, group_id: group_b.id) }
      let(:email)         { Faker::Internet.unique.email }
      let(:mail_hash) do
        {
          'x-zammad-ticket-id': ticket.id,
          to:                   email,
        }
      end

      before { create(:email_address, email:, channel: other_channel) }

      it 'drops the follow-up association for a foreign group' do
        filter(mail_hash, channel:)

        expect(mail_hash).to include('x-zammad-ticket-id': nil)
      end
    end

    context 'when the receiving group cannot be resolved' do
      let(:channel)   { create(:channel, group_id: nil) }
      let(:mail_hash) { { 'x-zammad-ticket-id': ticket.id, to: 'unknown@example.com' } }

      it 'keeps the follow-up association (preserves current behavior)' do
        filter(mail_hash, channel:)

        expect(mail_hash).to include('x-zammad-ticket-id': ticket.id)
      end
    end

    context 'when no follow-up ticket was detected' do
      let(:mail_hash) { { subject: 'a new request' } }

      it 'does not do anything' do
        filter(mail_hash, channel:)

        expect(mail_hash).not_to include(:'x-zammad-ticket-id')
      end
    end

    context 'when the detected ticket no longer exists' do
      let(:mail_hash) { { 'x-zammad-ticket-id': 0 } }

      it 'keeps the (non-resolvable) follow-up association untouched' do
        filter(mail_hash, channel:)

        expect(mail_hash).to include('x-zammad-ticket-id': 0)
      end
    end
  end

  context 'when the setting is disabled' do
    let(:setting_active) { false }

    it 'keeps the follow-up association even for a foreign group' do
      filter(mail_hash, channel:)

      expect(mail_hash).to include('x-zammad-ticket-id': ticket.id)
    end
  end
end
