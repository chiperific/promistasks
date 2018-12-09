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
      sign_in @user if current_user.nil?
      # send an email to vol coordinator
      if Rails.env.production?
        RegistrationMailer.with(user: @user).new_registration_notification.deliver_later
      else
        RegistrationMailer.with(user: @user).new_registration_notification.deliver_now
      end

      flash[:success] = "Welcome, #{@user.fname}"

      redirect_to root_path
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation, :register_as)
  end

  def account_update_params
    params.require(:user).permit(:name, :title,
                                 :staff, :client, :volunteer, :contractor, :admin,
                                 :adults, :children,
                                 :rate, :rate_cents, :rate_currency,
                                 :phone, :email, :password, :password_confirmation,
                                 :discarded_at, :register_as)
  end
end
