# frozen_string_literal: true

class UsersController < ApplicationController
  def index
  end

  def show
    @users = User.undiscarded
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
end
