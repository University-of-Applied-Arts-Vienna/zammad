# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Sets up the account an admin impersonates to see the interface with the given roles. Each admin
#   has an account of their own, so impersonating never takes over the session of a real user.
class Service::User::PrepareImpersonator < Service::Base
  requires_current_user!

  attr_reader :role_ids, :firstname, :lastname, :email

  def self.login_for(user)
    "impersonator-#{user.id}"
  end

  def self.find_for(user)
    ::User.find_by(login: login_for(user))
  end

  def self.impersonator?(user)
    user.login.to_s.match?(%r{\Aimpersonator-\d+\z})
  end

  def initialize(role_ids:, firstname:, lastname:, email:)
    @role_ids  = role_ids
    @firstname = firstname
    @lastname  = lastname
    @email     = email
  end

  def execute
    roles = ::Role.where(id: role_ids, active: true)
    raise Exceptions::UnprocessableContent, __('Please select at least one role.') if roles.empty?

    check_conflicting_roles!(roles)

    user = self.class.find_for(current_user) || ::User.new(login: self.class.login_for(current_user))
    user.assign_attributes(
      firstname: firstname,
      lastname:  lastname,
      email:     email,
      active:    true,
      roles:     roles,
    )
    user.save!

    user
  end

  private

  # User#validate_roles raises a plain error on conflicting roles, which would be a server error.
  def check_conflicting_roles!(roles)
    names = roles.map(&:name)

    roles.each do |role|
      conflict = Array(role.preferences[:not]).find { |name| names.include?(name) }
      next if !conflict

      raise Exceptions::UnprocessableContent, "Role #{role.name} conflicts with #{conflict}."
    end
  end
end
