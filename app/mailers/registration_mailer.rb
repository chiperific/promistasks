# frozen_string_literal: true

class RegistrationMailer < ApplicationMailer
  def new_registration_notification
    org = Organization.first
    @notify = org.volunteer_contact.present? ? org.volunteer_contact.email : org.default_email
    @new_user = params[:user]
    mail(to: @notify, subject: 'A new person signed up on PromiseTasks')
  end
end
