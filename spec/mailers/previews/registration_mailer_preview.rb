# Preview all emails at http://localhost:3000/rails/mailers/registration_mailer
class RegistrationMailerPreview < ActionMailer::Preview
  def new_registration_notification
    RegistrationMailer.with(user: User.first).new_registration_notification
  end
end
