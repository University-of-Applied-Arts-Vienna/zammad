# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  scope Rails.configuration.api_path do
    resources :admin_messages, except: :edit do
      collection do
        get  'current'
        get  'search'
        post 'search'
      end
    end
  end
end
