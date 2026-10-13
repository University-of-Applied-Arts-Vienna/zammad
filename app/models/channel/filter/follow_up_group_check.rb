# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::FollowUpGroupCheck

  # Makes the receiving channel/address group authoritative for follow-up detection.
  #
  # If a follow-up ticket was detected (subject hook or References/In-Reply-To) but it
  # belongs to a different group than the channel/address that actually received the
  # mail, the follow-up association is dropped so the email parser creates a new ticket
  # in the receiving group instead of appending to the foreign ticket.
  #
  # Before falling back to a new ticket, the References/In-Reply-To message ids are
  # checked for an article of a ticket in the receiving group. This is the case when a
  # group answers a mail another group sent from one of its tickets: the answer carries
  # the subject hook of the answering group's ticket, but references the mail the
  # requesting group sent, so it gets threaded into the requesting group's ticket.
  #
  # Runs after the regular follow-up detection (FollowUpCheck/FollowUpPossibleCheck) and
  # before IdentifyGroup, so clearing the follow-up id makes IdentifyGroup fall back to
  # the receiving group.
  def self.run(channel, mail, transaction_params)
    return if !Setting.get('postmaster_follow_up_new_ticket_for_different_group')

    ticket_id = mail[:'x-zammad-ticket-id']
    return if ticket_id.blank?

    ticket = Ticket.lookup(id: ticket_id)
    return if ticket.blank?

    receiving_group = resolve_receiving_group(channel, mail)

    # If the receiving group cannot be determined we keep the current behavior
    # and let the detected follow-up thread as before.
    return if receiving_group.blank?
    return if ticket.group_id == receiving_group.id

    # Clean the subject so the new ticket does not carry the foreign ticket hook
    # (which would otherwise re-thread later replies back to the foreign ticket).
    mail[:subject]                  = ticket.subject_clean(mail[:subject]) if mail[:subject].present?
    mail[:'x-zammad-ticket-id']     = nil
    mail[:'x-zammad-ticket-number'] = nil

    referenced_ticket = referenced_ticket_in_group(mail, receiving_group)
    if referenced_ticket
      Rails.logger.debug { "Follow-up for '##{ticket.number}' redirected: detected group ##{ticket.group_id} differs from receiving group ##{receiving_group.id}, using referenced ticket '##{referenced_ticket.number}'." }

      follow_up_referenced_ticket(channel, mail, transaction_params, referenced_ticket)
    else
      Rails.logger.debug { "Follow-up for '##{ticket.number}' ignored: detected group ##{ticket.group_id} differs from receiving group ##{receiving_group.id}, creating a new ticket." }
    end

    true
  end

  # Finds the most recent ticket of the receiving group which holds an article for one
  # of the References/In-Reply-To message ids.
  #
  # All articles of a message id are considered, not only the newest one: the mail a
  # group sent to another group's address exists twice (the outgoing article and the
  # imported copy in the other group's ticket), and the newest one is the foreign copy.
  def self.referenced_ticket_in_group(mail, group)
    message_id_md5s = Channel::Filter::FollowUpCheck.mail_references(mail)
      .split(%r{\s+})
      .compact_blank
      .map { |message_id| Digest::MD5.hexdigest(message_id) }
    return if message_id_md5s.blank?

    Ticket
      .joins(:articles)
      .where(group_id: group.id, ticket_articles: { message_id_md5: message_id_md5s })
      .reorder('ticket_articles.created_at DESC, ticket_articles.id DESC')
      .first
  end

  # The follow-up filters which ran before were evaluated against the foreign ticket, so
  # they are re-applied for the referenced ticket (merge target, owner reset and the
  # follow-up configuration of closed tickets).
  def self.follow_up_referenced_ticket(channel, mail, transaction_params, referenced_ticket)
    mail[:'x-zammad-ticket-id'] = referenced_ticket.id
    mail.delete(:'x-zammad-ticket-followup-owner')

    Channel::Filter::FollowUpMerged.run(channel, mail, transaction_params)
    Channel::Filter::FollowUpAssignment.run(channel, mail, transaction_params)
    Channel::Filter::FollowUpPossibleCheck.run(channel, mail, transaction_params)
  end

  # Resolves the group of the channel/address that received the mail.
  #
  # Deliberately mirrors Channel::Filter::IdentifyGroup#pick_group but without its
  # "first active group" fallback: an unresolvable receiving group must not be compared
  # against the detected ticket's group, as that could drop a legitimate follow-up.
  def self.resolve_receiving_group(channel, mail)
    if channel[:group_id]
      Group.lookup(id: channel[:group_id])
    else
      Channel::EmailParser.mail_to_group(mail[:to])
    end
  end
end
