# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AdminFoldersController < ApplicationController
  include CanPrioritize

  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(AdminFolder, params)
  end

  def show
    model_show_render(AdminFolder, params)
  end

  def create
    model_create_render(AdminFolder, params)
  end

  def update
    model_update_render(AdminFolder, params)
  end

  def destroy
    model_destroy_render(AdminFolder, params)
  end

  def search
    model_search_render(AdminFolder, params)
  end
end
