# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AdminMessage < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasOptionalGroups
  include AdminMessage::TriggersSubscriptions

  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  validates :message,  presence: true
  validates :start_at, presence: true
  validates :end_at,   presence: true
  validate  :validate_time_window

  sanitized_html :message, no_images: true

  # Messages that are enabled and within their configured time window right now.
  scope :live, lambda {
    now = Time.zone.now
    where(active: true).where(start_at: ..now).where(end_at: now..)
  }

=begin

deliver the one-time bell notification for every message that just became live
(called periodically by the scheduler, see db/seeds/schedulers.rb)

  AdminMessage.process

=end

  def self.process
    live.where(notification_sent_at: nil).find_each(&:deliver_notifications!)
  end

  # Messages currently visible to the given user (live and targeted at the user).
  def self.current_for(user)
    live.select { |message| message.recipient?(user) }
  end

  def live?
    active && start_at <= Time.zone.now && Time.zone.now <= end_at
  end

  # Whether the message targets the given user. Blank groups means everyone;
  # otherwise only agents with read access to one of the selected groups.
  def recipient?(user)
    return true if group_ids.blank?

    group_ids.intersect?(user.group_ids_access('read'))
  end

  # Active users that should receive this message.
  def recipients
    return User.where(active: true) if group_ids.blank?

    recipient_ids = group_ids.flat_map { |group_id| User.group_access_ids(group_id, 'read') }.uniq
    User.where(active: true, id: recipient_ids)
  end

  # Create the one-time bell notification for each recipient (idempotent via notification_sent_at).
  def deliver_notifications!
    return if notification_sent_at.present?
    return if !live?

    recipients.find_each do |user|
      OnlineNotification.add(
        user_id:       user.id,
        kind:          'admin_message',
        seen:          false,
        data:          { message:, admin_message_id: id },
        created_by_id: 1,
      )
    end

    # `update_column` skips callbacks, so notify clients explicitly to refresh their banners.
    update_column(:notification_sent_at, Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
    notify_clients_about_change
  end

  private

  def notify_clients_about_change
    self.class.trigger_subscriptions
    notify_clients_send(notify_clients_data(:update))
  end

  def validate_time_window
    return if start_at.blank? || end_at.blank?
    return if start_at < end_at

    errors.add(:end_at, __('must be after the start time'))
  end
end
