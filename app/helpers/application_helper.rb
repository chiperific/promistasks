# frozen_string_literal: true

module ApplicationHelper
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
end
