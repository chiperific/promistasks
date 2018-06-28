# frozen_string_literal: true

module UsersHelper
  def redirect_back_for_sync
    if request.env['HTTP_REFERER'].present? &&
       request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
      redirect_to request.env['HTTP_REFERER'] + '?syncing=true'
    else
      redirect_to properties_path(syncing: true)
    end
  end
end
