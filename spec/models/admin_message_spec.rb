# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AdminMessage, :aggregate_failures, type: :model do
  subject(:admin_message) { create(:admin_message) }

  describe 'validations' do
    it 'is valid with default attributes' do
      expect(admin_message).to be_valid
    end

    it 'requires a message' do
      expect(build(:admin_message, message: nil)).not_to be_valid
    end

    it 'requires start_at and end_at' do
      expect(build(:admin_message, start_at: nil)).not_to be_valid
      expect(build(:admin_message, end_at: nil)).not_to be_valid
    end

    it 'rejects an end that is not after the start' do
      record = build(:admin_message, start_at: 1.hour.from_now, end_at: 1.hour.ago)

      expect(record).not_to be_valid
      expect(record.errors[:end_at]).to be_present
    end

    it 'sanitizes the message HTML' do
      record = create(:admin_message, message: '<b>Heads up</b><script>alert(1)</script>')

      expect(record.message).to include('Heads up')
      expect(record.message).not_to include('<script>')
    end
  end

  describe '.live' do
    let!(:live) { create(:admin_message, :live) }

    before do
      create(:admin_message, :live, active: false)
      create(:admin_message, :upcoming)
      create(:admin_message, :expired)
    end

    it 'only contains active messages within their time window' do
      expect(described_class.live).to contain_exactly(live)
    end
  end

  describe '#recipient?' do
    let(:group)       { create(:group) }
    let(:agent)       { create(:agent, groups: [group]) }
    let(:other_agent) { create(:agent) }
    let(:customer)    { create(:customer) }

    context 'without groups (all users)' do
      it 'targets every user' do
        expect(admin_message.recipient?(agent)).to be(true)
        expect(admin_message.recipient?(customer)).to be(true)
      end
    end

    context 'with a group' do
      subject(:admin_message) { create(:admin_message, groups: [group]) }

      it 'targets agents with access to the group' do
        expect(admin_message.recipient?(agent)).to be(true)
      end

      it 'does not target agents without access or customers' do
        expect(admin_message.recipient?(other_agent)).to be(false)
        expect(admin_message.recipient?(customer)).to be(false)
      end
    end
  end

  describe '#deliver_notifications!' do
    let!(:agent) { create(:agent) }

    context 'when the message is live' do
      subject(:admin_message) { create(:admin_message, :live) }

      it 'creates one standalone bell notification per recipient and stamps the timestamp' do
        expect { admin_message.deliver_notifications! }
          .to change { OnlineNotification.where(user_id: agent.id).count }.by(1)

        expect(admin_message.reload.notification_sent_at).to be_present
      end

      it 'is idempotent across multiple runs' do
        admin_message.deliver_notifications!

        expect { admin_message.deliver_notifications! }
          .not_to change(OnlineNotification, :count)
      end

      it 'stores the message in an admin_message standalone notification' do
        admin_message.deliver_notifications!

        standalone = OnlineNotificationStandalone.last
        expect(standalone).to have_attributes(kind: 'admin_message')
        expect(standalone.data['message']).to eq(admin_message.message)
      end
    end

    context 'when the message is not live yet' do
      subject(:admin_message) { create(:admin_message, :upcoming) }

      it 'does not deliver anything' do
        expect { admin_message.deliver_notifications! }
          .not_to change(OnlineNotification, :count)
      end
    end
  end

  describe '.process' do
    let!(:live)     { create(:admin_message, :live) }
    let!(:upcoming) { create(:admin_message, :upcoming) }

    before { create(:agent) }

    it 'delivers notifications only for live, not-yet-notified messages' do
      described_class.process

      expect(live.reload.notification_sent_at).to be_present
      expect(upcoming.reload.notification_sent_at).to be_nil
    end
  end
end
