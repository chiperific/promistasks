# frozen_string_literal: true

class RefreshUsersClient
  def initialize
    User.staff.each do |user|
      RefreshPropertiesClient.new(user)
    end
  end
end
