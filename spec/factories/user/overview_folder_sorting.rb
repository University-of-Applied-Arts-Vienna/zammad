# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'user/overview_folder_sorting', aliases: %w[user_overview_folder_sorting] do
    overview_folder
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
