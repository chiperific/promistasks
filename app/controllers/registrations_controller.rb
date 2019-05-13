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
      # send an email to vol coordinator
      RegistrationMailer.with(user: @user).new_registration_notification.deliver_now

      if current_user.nil?
        sign_in @user
        flash[:success] = "Welcome, #{@user.fname}"
      else
        flash[:success] = "#{@user.fname} successfully created"
      end

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
