# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::FollowUpGroupCheck

  # Makes the receiving channel/address group authoritative for follow-up detection.
  #
  # If a follow-up ticket was detected (subject hook or References/In-Reply-To) but it
  # belongs to a different group than the channel/address that actually received the
  # mail, the follow-up association is dropped so the email parser creates a new ticket
  # in the receiving group instead of appending to the foreign ticket.
  #
  # Runs after the regular follow-up detection (FollowUpCheck/FollowUpPossibleCheck) and
  # before IdentifyGroup, so clearing the follow-up id makes IdentifyGroup fall back to
  # the receiving group.
  def self.run(channel, mail, _transaction_params)
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

    Rails.logger.debug { "Follow-up for '##{ticket.number}' ignored: detected group ##{ticket.group_id} differs from receiving group ##{receiving_group.id}, creating a new ticket." }

    # Clean the subject so the new ticket does not carry the foreign ticket hook
    # (which would otherwise re-thread later replies back to the foreign ticket).
    mail[:subject]                  = ticket.subject_clean(mail[:subject]) if mail[:subject].present?
    mail[:'x-zammad-ticket-id']     = nil
    mail[:'x-zammad-ticket-number'] = nil

    true
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
