# frozen_string_literal: true

class OrganizationsController < ApplicationController
  before_action :find_organization

  def show
    authorize @organization
  end

  def edit
    authorize @organization
  end

  def update
    authorize @organization
  end

  private

  def find_organization
    @organization = Organization.first
  end

  def organization_params
    params.require(:organization).permit(:name, :domain,
                                         :billing_contact_id,
                                         :maintenance_contact_id,
                                         :volunteer_contact_id)
  end
end
