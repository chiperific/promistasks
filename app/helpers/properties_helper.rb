# frozen_string_literal: true

module PropertiesHelper
  def year_ary(num)
    newest = Date.today.year
    oldest = (Date.today - num.years).year
    Array(oldest..newest).reverse
  end
end
