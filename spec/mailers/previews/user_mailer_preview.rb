# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/registration_mailer
class UserMailerPreview < ActionMailer::Preview
  def payments_reminder
    user = User.first
    UserMailer.payments_reminder(user, true)
  end
end
