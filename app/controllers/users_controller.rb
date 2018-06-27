# frozen_string_literal: true

class UsersController < ApplicationController
  # https://github.com/plataformatec/devise/wiki/How-To:-Manage-users-through-a-CRUD-interface

  def index
    authorize @users = User.undiscarded
  end

  def show
    authorize @user = User.find(params[:id])
    redirect_to users_path
  end

  def new
    authorize @user = User.new
    @hide_rate = 'scale-out'
  end

  def create
    authorize @user = User.find(params[:id])
  end

  def edit
    authorize @user = User.find(params[:id])
    @hide_rate = 'scale-out' unless @user.contractor?
  end

  def update
    authorize @user = User.find(params[:id])
    @user.discarded_at = user_params[:archive] == '1' ? Time.now : nil
    modified_params = user_params.except :archive
    if params[:password].nil?
      modified_params = user_params.except :password, :password_confirmation, :archive
    end
    if @user.update(modified_params)
      flash[:success] = 'Update succesful'
      redirect_to edit_user_path(@user)
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def destroy
    authorize @user = User.find(params[:id])
  end

  def discarded
    authorize @users = User.discarded
  end

  def api_sync
    authorize @user = User.find(params[:id])
    Delayed::Job.enqueue SyncUserWithApiJob.new(@user.id)
    # redirect_back fallback_location: root_path, allow_other_host: false, syncing: true
    redirect_to properties_path(syncing: true)
  end

  def alerts
    authorize @user = User.find(params[:id])
    # alerts include:
    # past-due tasks
    # properties over budget (if creator)
    # properties nearing budget (if creator)
    # Tasks due this week
    # Tasks due next week
    # tasks missing info
    # newly-assigned tasks (since last_sign_in_at?)
  end

  private

  def user_params
    params.require(:user).permit(:name, :title,
                                 :program_staff, :project_staff, :admin_staff,
                                 :client, :volunteer, :contractor,
                                 :rate, :rate_cents, :rate_currency,
                                 :phone1, :phone2, :address1, :address2, :city, :state, :postal_code,
                                 :email, :password, :password_confirmation,
                                 :system_admin, :archive)
  end
end
