# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user&.staff? || user&.admin?
  end

  def show?
    user&.staff? || user&.admin? || user == record
  end

  def tasks?
    user&.staff? || user&.admin? || user == record
  end

  def tasks_finder?
    user&.staff? || user&.admin? || user == record
  end

  def skills?
    user&.staff? || user&.admin? || user == record
  end

  def update_skills?
    user&.staff? || user&.admin? || user == record
  end

  def new?
    user&.staff? || user&.admin?
  end

  def create?
    # devise registrations for new users
    true
  end

  def edit?
    user&.staff? || user&.admin? || user == record
  end

  def update?
    user&.staff? || user&.admin? || user == record
  end

  def oauth_check?
    user&.staff? || user&.admin?
  end

  def api_sync?
    user&.admin? || user == record
  end

  def clear_completed_jobs?
    user&.oauth?
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

  def find_id_by_title?
    user&.admin?
  end
end
