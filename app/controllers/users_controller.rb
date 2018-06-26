# frozen_string_literal: true

class UsersController < ApplicationController
  # https://github.com/plataformatec/devise/wiki/How-To:-Manage-users-through-a-CRUD-interface

  def index
    @users = User.undiscarded
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
  end

  def discarded
    @users = User.discarded
  end

  def api_sync
    @user = User.find(params[:id])
    Delayed::Job.enqueue SyncUserWithApiJob.new(@user.id)
    redirect_to properties_path(syncing: true)
  end
end
