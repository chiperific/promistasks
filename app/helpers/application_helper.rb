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

  def parse_datetimes(params)
    %w[completed_at discarded_at due].each do |key|
      params[key] = Time.parse(params[key]) if params[key].present?
    end
    params
  end
end
