# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewSortingsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    render json: {
      overviews:                Ticket::Overviews.all(current_user: current_user, ignore_user_conditions: true),
      overview_sortings:        User::OverviewSorting.where(user: current_user),
      folders:                  visible_folders,
      overview_folder_sortings: User::OverviewFolderSorting.where(user: current_user),
    }
  end

  def show
    model_show_render(User::OverviewSorting, params)
  end

  def create
    model_create_render(User::OverviewSorting, params)
  end

  def update
    model_update_render(User::OverviewSorting, params)
  end

  def destroy
    ActiveRecord::Base.transaction do
      model_destroy_render(User::OverviewSorting, params)
    end

    Gql::Subscriptions::User::Current::OverviewOrderingUpdates
        .trigger_by(current_user)
  end

  def prio
    if reset_requested?
      update_order([])
    else
      entries = authorized_entries

      # Never wipe the personal order on an empty/unrecognized payload; only an
      #   explicit reset clears it.
      update_order(entries) if entries.present?
    end

    render json: { success: true }, status: :ok
  end

  private

  def reset_requested?
    ActiveModel::Type::Boolean.new.cast(params[:reset])
  end

  def update_order(entries)
    Service::User::Overview::UpdateTreeOrder
      .with_current_user(current_user)
      .execute(entries)

    Gql::Subscriptions::User::Current::OverviewOrderingUpdates
      .trigger_by(current_user)
  end

  def visible_folders
    Service::User::Overview::Folder::List
      .with_current_user(current_user)
      .execute(ignore_user_conditions: true)
  end

  # Keep only the entries the user is actually allowed to order, preserving the
  #   given (depth-first) order.
  def authorized_entries
    # `.reorder(nil)` drops the default prio/name ordering: it is irrelevant for
    #   the id set and otherwise breaks `SELECT DISTINCT ... pluck(:id)` on
    #   PostgreSQL (ORDER BY columns must be in the DISTINCT select list).
    authorized_overview_ids = Ticket::Overviews
      .all(current_user:, ignore_user_conditions: true)
      .reorder(nil)
      .pluck(:id).to_set

    authorized_folder_ids = visible_folders.reorder(nil).pluck(:id).to_set

    requested_entries.filter_map do |entry|
      case entry[:type]
      when 'Overview'
        next if authorized_overview_ids.exclude?(entry[:id])
      when 'OverviewFolder'
        next if authorized_folder_ids.exclude?(entry[:id])
      else
        next
      end

      entry
    end
  end

  # Normalizes the request body into typed `{ type:, id: }` entries in display
  #   order. Accepts the tree payload (`entries`) and the legacy overview-only
  #   payload (`prios`, e.g. from a cached older asset) so an outdated client
  #   keeps ordering overviews instead of silently losing its order.
  def requested_entries
    if params[:entries].present?
      Array(params[:entries]).map { |entry| { type: entry[:type], id: entry[:id].to_i } }
    else
      Array(params[:prios]).map { |pair| { type: 'Overview', id: Array(pair).first.to_i } }
    end
  end
end
