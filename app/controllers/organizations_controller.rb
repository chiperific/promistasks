# frozen_string_literal: true

class OrganizationsController < ApplicationController
  before_action :find_organization

  def show
    authorize @organization

    @info_hash = {
      'Name': @organization.name,
      'Web domain': @organization.domain,
      'Default email': @organization.default_email,
      'Default phone': @organization.default_phone
    }

    @rel_aoh = [
      {
        a: 'Billing Contact:',
        b: @organization.billing_contact.present? ? @organization.billing_contact.name : 'Not set',
        c: @organization.billing_contact.present? ? user_path(@organization.billing_contact) : nil,
        d: 'Notified of all upcoming payments, regardless of who created them.'
      },
      {
        a: 'Maintenance Contact:',
        b: @organization.maintenance_contact.present? ? @organization.maintenance_contact.name : 'Not set',
        c: @organization.maintenance_contact.present? ? user_path(@organization.maintenance_contact) : nil,
        d: 'Notified of all maintenance requests, regardless of park and property.'
      },
      {
        a: 'Volunteer Contact:',
        b: @organization.volunteer_contact.present? ? @organization.volunteer_contact.name : 'Not set',
        c: @organization.volunteer_contact.present? ? user_path(@organization.volunteer_contact) : nil,
        d: 'Notified when a new person signs up, has their contact info displayed on public tasks and homepage.'
      }
    ]
  end

  def edit
    authorize @organization
  end

  def update
    authorize @organization

    if @organization.update(organization_params)
      redirect_to @return_path, notice: 'Organization updated'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
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
