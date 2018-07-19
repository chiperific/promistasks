# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user&.staff?
  end

  def show?
    user&.staff? || user == record
  end

  def tasks?
    user&.staff? || user == record
  end

  def skills?
    user&.staff? || user == record
  end

  def update_skills?
    user&.staff? || user == record
  end

  def new?
    user&.staff?
  end

  def create?
    # devise registrations for new users
    true
  end

  def edit?
    user&.system_admin? || user == record
  end

  def update?
    user&.system_admin? || user == record
  end

  def destroy?
    user&.system_admin? && user != record
  end

  def discarded?
    user&.system_admin?
  end

  def current_user_id?
    user.not_client?
  end

  def api_sync?
    user&.system_admin? || user == record
  end

  def clear_completed_jobs?
    user&.staff?
  end

  def alerts?
    user&.system_admin? || user == record
  end

  def owner_enum?
    user&.not_client?
  end

  def subject_enum?
    user&.not_client?
  end

  def find_id_by_name?
    user&.not_client?
  end
end
