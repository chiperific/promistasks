# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    if current_user
      @tasklists = TaskManager.new.list_tasklists(current_user)
    else
      @tasklists = 'you\'re not signed in'
    end
  end
end
