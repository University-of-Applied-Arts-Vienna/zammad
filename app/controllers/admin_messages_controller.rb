# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AdminMessagesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(AdminMessage, params)
  end

  def show
    model_show_render(AdminMessage, params)
  end

  def create
    model_create_render(AdminMessage, params)
  end

  def update
    model_update_render(AdminMessage, params)
  end

  def search
    model_search_render(AdminMessage, params)
  end

  def destroy
    model_destroy_render(AdminMessage, params)
  end

  # Messages currently relevant for the requesting user; consumed by the warning banner.
  def current
    messages = AdminMessage.current_for(current_user).map do |message|
      {
        id:       message.id,
        message:  message.message,
        start_at: message.start_at,
        end_at:   message.end_at,
      }
    end

    render json: messages
  end
end
