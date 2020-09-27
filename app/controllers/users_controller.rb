# frozen_string_literal: true

class UsersController < ApplicationController
  # https://github.com/plataformatec/devise/wiki/How-To:-Manage-users-through-a-CRUD-interface

  def in
    # sign-in screen
    # trigger omniauth
  end

  def oauth
    # receive the omniauth response
    # find or create the user
    # create the session
    # success: redirect_to show
    # failure: redirect_to :in
  end

  def show
    # main page, includes sign-out button
    # aliased as '/canvas'
  end

  def out
    # destroy the session
    # redirect_to :in
  end

  def destroy
    # destroy the user
    # redirect_to :out
  end
end
