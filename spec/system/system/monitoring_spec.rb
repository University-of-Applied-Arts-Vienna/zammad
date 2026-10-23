# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Monitoring', type: :system do

  context 'when showing the token' do
    it 'works correctly' do
      visit 'system/monitoring'

      within :active_content do
        token = find('.js-token').value
        url   = find('.js-url').value
        expect(url).to include(token)

        click '.js-resetToken'
        new_token = find('.js-token').value
        new_url   = find('.js-url').value
        expect(new_url).to include(new_token)
        expect(token).not_to eq(new_token)
      end
    end
  end

  context 'when showing emails that could not be processed' do
    before do
      create(:failed_email, channel: create(:email_channel, mail_server_user: 'support@example.com'))
    end

    it 'lists them with their email account' do
      visit 'system/monitoring'

      within :active_content do
        within '.js-failedEmailsTable' do
          expect(page).to have_text('support@example.com')
            .and have_text('ME Bob <me@example.com>')
            .and have_text('some subject')
        end
      end
    end
  end

  context 'when no email failed' do
    it 'says so' do
      visit 'system/monitoring'

      within :active_content do
        expect(page).to have_text('There are no emails that could not be processed.')
      end
    end
  end
end
