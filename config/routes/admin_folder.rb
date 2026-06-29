# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # admin folders
  match api_path + '/admin_folders',         to: 'admin_folders#index',   via: :get
  match api_path + '/admin_folders/search',  to: 'admin_folders#search',  via: %i[get post]
  match api_path + '/admin_folders/:id',     to: 'admin_folders#show',    via: :get
  match api_path + '/admin_folders',         to: 'admin_folders#create',  via: :post
  match api_path + '/admin_folders/:id',     to: 'admin_folders#update',  via: :put
  match api_path + '/admin_folders/:id',     to: 'admin_folders#destroy', via: :delete
  match api_path + '/admin_folders_prio',    to: 'admin_folders#prio',    via: :post

end
