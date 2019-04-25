# frozen_string_literal: true

module ApplicationHelper
  def pluralize_without_count(count, noun, text = nil)
    if count != 0
      count == 1 ? "#{noun}#{text}" : "#{noun.pluralize}#{text}"
    end
  end

  def human_boolean(boolean)
    return boolean unless boolean.is_a?(TrueClass) || boolean.is_a?(FalseClass)

    boolean ? 'Yes' : 'No'
  end

  def human_date(date)
    return date unless date.is_a?(Date) || date.is_a?(Time)

    date&.strftime('%b %-d, %Y')
  end

  def human_datetime(datetime)
    return datetime unless datetime.is_a? Time

    datetime&.strftime('%-m/%-d @ %l:%M:%S %p %Z')
  end

  def human_money(money)
    return money unless money.is_a? Money

    view_context.humanized_money_with_symbol(money)
  end
end
