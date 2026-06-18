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
    Service::User::Overview::UpdateTreeOrder
      .with_current_user(current_user)
      .execute(authorized_entries)

    Gql::Subscriptions::User::Current::OverviewOrderingUpdates
      .trigger_by(current_user)

    render json: { success: true }, status: :ok
  end

  private

  def visible_folders
    Service::User::Overview::Folder::List
      .with_current_user(current_user)
      .execute(ignore_user_conditions: true)
  end

  # Keep only the entries the user is actually allowed to order, preserving the
  #   given (depth-first) order.
  def authorized_entries
    authorized_overview_ids = Ticket::Overviews
      .all(current_user:, ignore_user_conditions: true)
      .pluck(:id).to_set

    authorized_folder_ids = visible_folders.pluck(:id).to_set

    Array(params[:entries]).filter_map do |entry|
      id = entry[:id].to_i

      case entry[:type]
      when 'Overview'
        next if authorized_overview_ids.exclude?(id)
      when 'OverviewFolder'
        next if authorized_folder_ids.exclude?(id)
      else
        next
      end

      { type: entry[:type], id: }
    end
  end
end
