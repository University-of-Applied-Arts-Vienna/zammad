# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :overview_folder do
    sequence(:name) { |n| "Test Folder #{n}" }
    sequence(:prio) { |n| n }
    active          { true }
    updated_by_id   { 1 }
    created_by_id   { 1 }
  end
end
