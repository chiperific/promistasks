# frozen_string_literal: true

module ApplicationHelper
  def pluralize_without_count(count, noun, text = nil)
    if count != 0
      count == 1 ? "#{noun}#{text}" : "#{noun.pluralize}#{text}"
    end
  end

  def human_boolean(boolean)
    boolean ? 'Yes' : 'No'
  end

  def human_date(date)
    date&.strftime('%b %-d, %Y')
  end

  def human_datetime(datetime)
    datetime&.strftime('%-m/%-d @ %l:%M:%S %p %Z')
  end

  def human_money(money)
    view_context.humanized_money_with_symbol(money)
  end
end
