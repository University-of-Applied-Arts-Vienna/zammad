# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::BaseEmailInbound
  class MessageValidator
    attr_reader :headers, :size

    # @param headers [Hash] in key-value format
    # @param size [Integer] in bytes
    def initialize(headers, size = nil)
      @headers = headers
      @size    = size
    end

    # Checks if email is not too big for processing
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def too_large?
      max_message_size = Setting.get('postmaster_max_size').to_f
      real_message_size = size.to_f / 1024 / 1024
      if real_message_size > max_message_size
        return [real_message_size, max_message_size]
      end

      false
    end

    # Checks if a message with the given headers is a Zammad verify message
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def verify_message?
      headers['X-Zammad-Verify'] == 'true'
    end

    # Checks if a message with the given headers marked to be ignored by Zammad
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def ignore?
      headers['X-Zammad-Ignore'] == 'true'
    end

    # Checks if a message is a new Zammad verify message
    #
    # Returns false only if a verify message is less than 30 minutes old
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def fresh_verify_message?
      return false if !verify_message?
      return false if headers['X-Zammad-Verify-Time'].blank?

      begin
        verify_time = Time.zone.parse(headers['X-Zammad-Verify-Time'])
      rescue => e
        Rails.logger.error e
        return false
      end

      verify_time > 30.minutes.ago
    end

    # Checks if a message is already imported in a given channel
    # This check is skipped for channels which do not keep messages on the server
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def already_imported?(keep_on_server, channel)
      return false if !keep_on_server

      return false if !headers

      local_message_id = headers['Message-ID']
      return false if local_message_id.blank?

      local_message_id_md5 = Digest::MD5.hexdigest(local_message_id)
      article = Ticket::Article.where(message_id_md5: local_message_id_md5).reorder('created_at DESC, id DESC').limit(1).first
      return false if !article

      # verify if message is already imported via same channel, if not, import it again
      ticket = article.ticket
      return false if ticket&.preferences && ticket.preferences[:channel_id].present? && channel.present? && ticket.preferences[:channel_id] != channel[:id]

      return false if different_receiving_group?(ticket, channel)

      true
    end

    private

    # Checks if a known message arrived at a channel which belongs to another group than the
    # ticket the message is already known from.
    #
    # Tickets which were not created by an email channel carry no `preferences[:channel_id]`
    # (it is only set in `Channel::EmailParser`), so the channel comparison in
    # `already_imported?` cannot tell an echo of our own mail apart from a mail that another
    # group legitimately received. Comparing the groups in that case keeps a mail which was
    # sent from one Zammad group to another one importable for the receiving group.
    #
    # This does not cause repeated imports: afterwards the newest article for the message id
    # belongs to a ticket of the receiving group - either a newly created one, which carries
    # the receiving `preferences[:channel_id]`, or a follow-up, whose `group_id` matches the
    # receiving channel. Independently of that the drivers fetch unread messages only and
    # flag a processed one as read, so even a message which produces no article at all is
    # only ever fetched once.
    def different_receiving_group?(ticket, channel)
      return false if !Setting.get('postmaster_follow_up_new_ticket_for_different_group')
      return false if ticket.blank? || channel.blank?

      # Already covered by the channel comparison in `already_imported?`.
      return false if ticket.preferences[:channel_id].present?

      # Channels without a (still existing) group are out of scope: the receiving group would
      # only be resolvable from the recipient address, which happens later in
      # `Channel::Filter::IdentifyGroup`. Resolve it the same way
      # `Channel::Filter::FollowUpGroupCheck` does, so both can never disagree and import a
      # message which is then threaded onto the foreign group's ticket anyway.
      return false if channel[:group_id].blank?

      receiving_group = Group.lookup(id: channel[:group_id])
      return false if receiving_group.blank?

      ticket.group_id != receiving_group.id
    end
  end
end
