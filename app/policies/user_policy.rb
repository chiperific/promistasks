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

  def tasks_finder?
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
    user&.admin? || user == record
  end

  def update?
    user&.admin? || user == record
  end

  def oauth_check?
    user&.staff?
  end

  def api_sync?
    user&.admin? || user == record
  end

  def clear_completed_jobs?
    user&.staff?
  end

  def alerts?
    user&.admin? || user == record
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
