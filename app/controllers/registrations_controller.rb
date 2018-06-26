# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  def create
    authorize @user = User.new(sign_up_params)

    case sign_up_params[:register_as]
    when 'Volunteer'
      @user.volunteer = true
    when 'Contractor'
      @user.contractor = true
    when 'Client'
      @user.client = true
    end

    if @user.save
      flash[:success] = "Welcome, #{@user.fname}"
      redirect_to root_path
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :register_as)
  end

  def account_update_params
    params.require(:user).permit(:name, :title,
                                 :program_staff, :project_staff, :admin_staff,
                                 :client, :volunteer, :contractor,
                                 :rate, :rate_cents, :rate_currency,
                                 :phone1, :phone2, :address1, :address2, :city, :state, :postal_code,
                                 :email, :password, :password_confirmation,
                                 :system_admin, :discarded_at, :register_as)
  end
end
