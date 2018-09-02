# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

skills = %w[plumbing HVAC drywall painting electrical cleaning landscaping roofing siding carpentry framing tiling masonry concrete asphalt demolition trim doors furniture insulating countertops cabinets]
skills.each do |skill|
  Skill.create(name: skill.capitalize)
end

Organization.new.save!
