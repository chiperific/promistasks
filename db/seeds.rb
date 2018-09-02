# frozen_string_literal: true

skills = %w[plumbing HVAC drywall painting electrical cleaning landscaping roofing siding carpentry framing tiling masonry concrete asphalt demolition trim doors furniture insulating countertops cabinets]
skills.each do |skill|
  Skill.create(name: skill.capitalize)
end

Organization.new.save!
