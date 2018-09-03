# frozen_string_literal: true

class SystemSpecGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :spec_name, type: :string

  def generate_spec
    template 'system_spec.rb', "spec/system/#{file_name}_spec.rb"
  end

  private

  def file_name
    spec_name.underscore
  end

  def human_string
    spec_name.underscore.humanize
  end
end
