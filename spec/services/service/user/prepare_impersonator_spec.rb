# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PrepareImpersonator, :aggregate_failures do

  let(:admin)    { create(:admin) }
  let(:role_ids) { [Role.find_by(name: 'Agent').id] }

  def execute(user = admin)
    described_class.execute(current_user: user, role_ids:, firstname: 'Preview', lastname: 'Account', email: "preview-#{user.id}@example.com")
  end

  it 'creates an active account of the admin with the given roles' do
    user = execute

    expect(user).to have_attributes(
      login:     "impersonator-#{admin.id}",
      firstname: 'Preview',
      email:     "preview-#{admin.id}@example.com",
      active:    true,
      roles:     [Role.find_by(name: 'Agent')],
    )
    expect(described_class.impersonator?(user)).to be(true)
  end

  it 'reuses the account and replaces its roles' do
    user = execute
    user.update!(active: false)

    role_ids.replace([Role.find_by(name: 'Customer').id])

    expect(execute).to eq(user)
    expect(user.reload).to have_attributes(active: true, roles: [Role.find_by(name: 'Customer')])
  end

  it 'gives each admin an account of their own' do
    expect(execute).not_to eq(execute(create(:admin)))
  end

  it 'does not see a real user as an impersonator' do
    expect(described_class.impersonator?(admin)).to be(false)
  end

  context 'without a role' do
    let(:role_ids) { [] }

    it 'fails' do
      expect { execute }.to raise_error(Exceptions::UnprocessableContent, 'Please select at least one role.')
    end
  end

  context 'with conflicting roles' do
    let(:role_ids) { [create(:role, preferences: { not: ['Agent'] }).id, Role.find_by(name: 'Agent').id] }

    it 'fails' do
      expect { execute }.to raise_error(Exceptions::UnprocessableContent, %r{conflicts with Agent})
    end
  end
end
