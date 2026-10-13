# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Lets groups work on a request another group sent them from one of its tickets
# without emailing answers back.
#
# When a group emails another group's address from a ticket, the receiving group gets
# its own ticket, whose first article is the imported copy of that mail. Both articles
# share the same message id, which identifies the origin ticket.
#
# - the two tickets get linked, so agents of both groups see the relation
# - public notes on the receiving group's ticket are copied as internal notes into the
#   origin ticket, which gets reopened like on a follow-up
#
# Only notes of the receiving group's ticket are copied (not the other way round), and
# copies are internal, so they are neither copied again nor sent out by triggers.
class Transaction::InterGroupNoteCopy

=begin
  {
    object: 'Ticket',
    type: 'update',
    object_id: 123,
    article_id: 123,
    interface_handle: 'application_server', # application_server|websocket|scheduler
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    },
    created_at: Time.zone.now,
    user_id: 123,
  },
=end

  # Returns the ticket of another group the given ticket was requested from, i.e. the
  # ticket which holds the outgoing email the first article of the given ticket was
  # imported from.
  def self.origin_ticket(ticket)
    first_article = ticket.articles.first
    return if first_article.blank?
    return if first_article.message_id_md5.blank?
    return if first_article.type.name != 'email'

    Ticket
      .joins(:articles)
      .where.not(id: ticket.id)
      .where.not(group_id: ticket.group_id)
      .where(ticket_articles: {
               message_id_md5: first_article.message_id_md5,
               sender_id:      Ticket::Article::Sender.lookup(name: 'Agent').id,
               type_id:        Ticket::Article::Type.lookup(name: 'email').id,
             })
      .reorder('ticket_articles.created_at ASC, ticket_articles.id ASC')
      .first
  end

  def initialize(item, params = {})
    @item = item
    @params = params
  end

  def perform
    return if Setting.get('import_mode')
    return if !Setting.get('postmaster_follow_up_new_ticket_for_different_group')
    return if @item[:object] != 'Ticket'

    return if !ticket

    # Link new tickets right away, later only check tickets which got a note.
    return if @item[:type] != 'create' && !copyable_article?
    return if !origin_ticket

    link_tickets

    return if !copyable_article?

    # Act as the author of the note, so the copy and its attachments are attributed to them.
    UserInfo.with_user_id(article.created_by_id) do
      Transaction.execute do
        copy_article
        reopen_origin_ticket
      end
    end
  end

  private

  def ticket
    @ticket ||= Ticket.find_by(id: @item[:object_id])
  end

  def article
    return if !@item[:article_id]

    @article ||= Ticket::Article.find_by(id: @item[:article_id])
  end

  def origin_ticket
    @origin_ticket ||= begin
      origin = self.class.origin_ticket(ticket)
      origin && (Channel::Filter::FollowUpMerged.find_merge_follow_up_ticket(origin) || origin)
    end
  end

  def copyable_article?
    return false if !article
    return false if article.ticket_id != ticket.id
    return false if article.internal
    return false if article.type.name != 'note'
    return false if article.sender.name != 'Agent'
    return false if article.preferences[:inter_group_note_copy].present?

    true
  end

  def link_tickets
    linked = Link.list(link_object: 'Ticket', link_object_value: ticket.id).any? do |link|
      link['link_object'] == 'Ticket' && link['link_object_value'] == origin_ticket.id
    end
    return if linked

    Link.add(
      link_type:                'normal',
      link_object_source:       'Ticket',
      link_object_source_value: origin_ticket.id,
      link_object_target:       'Ticket',
      link_object_target_value: ticket.id,
    )
  end

  def copy_article
    copy = Ticket::Article.create!(
      ticket_id:     origin_ticket.id,
      type_id:       article.type_id,
      sender_id:     article.sender_id,
      internal:      true,
      subject:       article.subject,
      content_type:  article.content_type,
      body:          article.body,
      origin_by_id:  article.origin_by_id,
      preferences:   {
        inter_group_note_copy: {
          ticket_id:  ticket.id,
          article_id: article.id,
          group_id:   ticket.group_id,
        },
      },
      created_by_id: article.created_by_id,
      updated_by_id: article.created_by_id,
    )

    article.clone_attachments(copy.class.name, copy.id)

    copy
  end

  # Reopen the origin ticket like a follow-up email does, unless it is still new.
  def reopen_origin_ticket
    return if origin_ticket.state_id == Ticket::State.find_by(default_create: true)&.id

    follow_up_state = Ticket::State.find_by(default_follow_up: true)
    return if !follow_up_state
    return if origin_ticket.state_id == follow_up_state.id

    origin_ticket.update!(state: follow_up_state, updated_by_id: article.created_by_id)
  end
end
