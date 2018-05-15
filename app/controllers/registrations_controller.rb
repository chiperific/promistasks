# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation,
                                 :client, :volunteer, :contractor)
  end

  def account_update_params
    params.require(:user).permit(:name, :title,
                                 :program_staff, :project_staff, :admin_staff,
                                 :client, :volunteer, :contractor,
                                 :rate, :rate_cents, :rate_currency,
                                 :phone1, :phone2, :address1, :address2, :city, :state, :postal_code,
                                 :email, :password, :password_confirmation,
                                 :system_admin, :deus_ex_machina, :discarded_at)
  end
end
