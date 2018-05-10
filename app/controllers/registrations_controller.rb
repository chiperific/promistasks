# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation,
                                 :client, :volunteer, :contractor)
  end

  def account_update_params
    params.require(:user).permit(:name, :title, :email, :password, :password_confirmation,
                                 :client, :volunteer, :contractor, :google_image_link,
                                 :system_admin, :program_staff, :project_staff, :admin_staff,
                                 :phone1, :phone2, :address1, :address2, :city, :state, :postal_code,
                                 :rate_cents, :rate_currency, :discarded_at)
  end
end
