# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::BaseEmailInbound::MessageValidator do
  describe '#already_imported?' do
    subject(:validator) { described_class.new(headers) }

    let(:headers)    { { 'Message-ID' => message_id } }
    let(:message_id) { "<#{SecureRandom.uuid}@zammad.example.com>" }

    let(:ticket_group)    { create(:group) }
    let(:receiving_group) { create(:group) }
    let(:channel)         { create(:channel, group: receiving_group) }

    let(:ticket) { create(:ticket, group: ticket_group) }

    before do
      Setting.set('postmaster_follow_up_new_ticket_for_different_group', true)
    end

    context 'when the channel does not keep messages on the server' do
      it 'is not already imported' do
        expect(validator.already_imported?(false, channel)).to be(false)
      end
    end

    context 'when no article with the message id exists' do
      it 'is not already imported' do
        expect(validator.already_imported?(true, channel)).to be(false)
      end
    end

    context 'when the message id has no value' do
      let(:headers) { { 'Message-ID' => '' } }

      it 'is not already imported' do
        expect(validator.already_imported?(true, channel)).to be(false)
      end
    end

    context 'without a channel' do
      before { create(:ticket_article, ticket:, message_id:) }

      it 'is already imported' do
        expect(validator.already_imported?(true, nil)).to be(true)
      end
    end

    context 'when the known ticket was created by an email channel' do
      before do
        ticket.update!(preferences: { channel_id: other_channel_id })
        create(:ticket_article, ticket:, message_id:)
      end

      context 'with another channel than the receiving one' do
        let(:other_channel_id) { channel.id + 1 }

        it 'is not already imported' do
          expect(validator.already_imported?(true, channel)).to be(false)
        end
      end

      context 'with the receiving channel' do
        let(:other_channel_id) { channel.id }

        it 'is already imported' do
          expect(validator.already_imported?(true, channel)).to be(true)
        end
      end
    end

    context 'when the known ticket was not created by an email channel' do
      before { create(:ticket_article, ticket:, message_id:) }

      context 'when the receiving channel belongs to another group' do
        it 'is not already imported, so the receiving group gets its own ticket' do
          expect(validator.already_imported?(true, channel)).to be(false)
        end

        context 'when the setting is disabled' do
          before { Setting.set('postmaster_follow_up_new_ticket_for_different_group', false) }

          it 'is already imported' do
            expect(validator.already_imported?(true, channel)).to be(true)
          end
        end

        context 'when the receiving channel has no group' do
          let(:channel) { create(:channel, group: nil) }

          it 'is already imported' do
            expect(validator.already_imported?(true, channel)).to be(true)
          end
        end

        context 'when the receiving group already imported the message' do
          # Created after the outer article on purpose: `already_imported?` looks at the
          # newest article for the message id, which must be the receiving group's one.
          before do
            receiving_ticket = create(:ticket, group: receiving_group, preferences: { channel_id: channel.id })
            create(:ticket_article, ticket: receiving_ticket, message_id:)
          end

          it 'is already imported, so the message does not get imported twice' do
            expect(validator.already_imported?(true, channel)).to be(true)
          end
        end
      end

      context 'when the receiving channel belongs to the same group' do
        let(:channel) { create(:channel, group: ticket_group) }

        it 'is already imported' do
          expect(validator.already_imported?(true, channel)).to be(true)
        end
      end
    end
  end
end
