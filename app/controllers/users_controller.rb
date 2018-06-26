# frozen_string_literal: true

class UsersController < ApplicationController
  # https://github.com/plataformatec/devise/wiki/How-To:-Manage-users-through-a-CRUD-interface

  def index
    authorize @users = User.undiscarded
  end

  def show
    authorize @user = User.find(params[:id])
  end

  def new
    authorize @user = User.new
  end

  def create
    authorize @user = User.find(params[:id])
  end

  def edit
    authorize @user = User.find(params[:id])
  end

  def update
    authorize @user = User.find(params[:id])
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
    redirect_to properties_path(syncing: true)
  end
end
