# frozen_string_literal: true

module PropertiesHelper
  def year_ary(num)
    newest = Date.today.year
    oldest = (Date.today - num.years).year
    Array(oldest..newest).reverse
  end

  def utilities_links(property)
    return 'none' if property.utilities_list.is_a? String
    ary = []
    property.utilities_list.each do |u|
      ary << link_to(u.name, u)
    end
    ary.join(',').html_safe
  end
end
