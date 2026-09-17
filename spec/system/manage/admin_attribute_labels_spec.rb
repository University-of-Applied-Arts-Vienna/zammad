# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Admin attribute labels', type: :system do
  def add_selector_row(attribute_name)
    within("[data-attribute-name=\"#{attribute_name}\"]") do
      find('.js-add').click
    end
  end

  def option_labels(selector)
    page.evaluate_script("Array.from(document.querySelectorAll('#{selector} option')).map(function(o) { return o.text })")
  end

  it 'shows the technical name of a trigger condition and action attribute' do
    visit '/#manage/trigger'
    find('[data-type=new]').click

    in_modal disappears: false do
      expect(page).to have_css('[data-attribute-name=condition] .js-attributeSelector select')

      expect(option_labels('[data-attribute-name=condition] .js-attributeSelector select'))
        .to include('State (state_id)', 'Group (group_id)')
      expect(option_labels('[data-attribute-name=perform] .js-attributeSelector select'))
        .to include('State (state_id)', 'Owner (owner_id)')
    end
  end

  it 'shows the technical name of a core workflow condition and action attribute' do
    visit '/#system/core_workflow'
    find('[data-type=new]').click

    in_modal disappears: false do
      select 'Ticket', from: 'object'

      add_selector_row('condition_selected')
      add_selector_row('perform')

      expect(page).to have_css('[data-attribute-name="condition_selected"] select option', minimum: 1)

      expect(option_labels('[data-attribute-name="condition_selected"] .js-attributeSelector select'))
        .to include('State (state_id)', 'Priority (priority_id)')
      expect(option_labels('[data-attribute-name="perform"] .js-attributeSelector select'))
        .to include('State (state_id)', 'Owner (owner_id)')
    end
  end

  it 'shows the technical name in the overview attribute, sorting and grouping pickers' do
    visit '/#manage/overviews'
    find('[data-type=new]').click

    in_modal disappears: false do
      expect(page).to have_css('[data-attribute-name="order::by"] select')

      expect(option_labels('[data-attribute-name="order::by"] select')).to include('State (state_id)')
      expect(option_labels('[data-attribute-name="group_by"] select')).to include('State (state_id)')

      within('[data-attribute-name="view::s"]') do
        expect(page).to have_text('State (state_id)')
      end
    end
  end

  context 'with two custom ticket attributes sharing a display name', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, name: 'category_one', display: 'Category')
      create(:object_manager_attribute_text, name: 'category_two', display: 'Category')
      ObjectManager::Attribute.migration_execute
      true
    end

    it 'keeps them distinguishable in the trigger condition picker' do
      visit '/#manage/trigger'
      find('[data-type=new]').click

      in_modal disappears: false do
        expect(page).to have_css('[data-attribute-name=condition] .js-attributeSelector select')

        expect(option_labels('[data-attribute-name=condition] .js-attributeSelector select'))
          .to include('Category (category_one)', 'Category (category_two)')
      end
    end

    it 'keeps them distinguishable in the overview attribute picker' do
      visit '/#manage/overviews'
      find('[data-type=new]').click

      in_modal disappears: false do
        expect(page).to have_css('[data-attribute-name="order::by"] select')

        expect(option_labels('[data-attribute-name="order::by"] select'))
          .to include('Category (category_one)', 'Category (category_two)')
      end
    end
  end
end
