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
end
