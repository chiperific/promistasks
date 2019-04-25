# frozen_string_literal: true
unless Rails.env.production?
  FactoryBot.use_parent_strategy = false
end
