# frozen_string_literal: true

class RegistrationMailer < ApplicationMailer

  def new_registration_notification
    @notify = Organization.first.volunteer_contact
    @new_user = params[:user]
    mail(to: @notify.email, subject: 'New user signed up on PromiseTasks')
  end
end
