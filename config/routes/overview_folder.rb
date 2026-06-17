# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # overview folders
  match api_path + '/overview_folders',         to: 'overview_folders#index',   via: :get
  match api_path + '/overview_folders/search',  to: 'overview_folders#search',  via: %i[get post]
  match api_path + '/overview_folders/:id',     to: 'overview_folders#show',    via: :get
  match api_path + '/overview_folders',         to: 'overview_folders#create',  via: :post
  match api_path + '/overview_folders/:id',     to: 'overview_folders#update',  via: :put
  match api_path + '/overview_folders/:id',     to: 'overview_folders#destroy', via: :delete
  match api_path + '/overview_folders_prio',    to: 'overview_folders#prio',    via: :post

end
