class ExcludePropertyUser < ApplicationRecord

  belongs_to :user, inverse_of: :exclude_property_users
  belongs_to :property, inverse_of: :exclude_property_users

  validates_presence_of :user, :property
end
