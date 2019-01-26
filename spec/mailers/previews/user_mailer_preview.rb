# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/registration_mailer
class UserMailerPreview < ActionMailer::Preview
  def payments_reminder
    payments = Payment.due_within(14)
    user = User.first
    UserMailer.payments_reminder(user, payments)
  end
end
