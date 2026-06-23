# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :admin_message do
    message       { 'System maintenance is scheduled for tonight.' }
    start_at      { Time.current }
    end_at        { 1.day.from_now }
    active        { true }
    created_by_id { 1 }
    updated_by_id { 1 }

    trait :live do
      start_at { 1.hour.ago }
      end_at   { 1.hour.from_now }
    end

    trait :upcoming do
      start_at { 1.hour.from_now }
      end_at   { 2.hours.from_now }
    end

    trait :expired do
      start_at { 2.hours.ago }
      end_at   { 1.hour.ago }
    end
  end
end
