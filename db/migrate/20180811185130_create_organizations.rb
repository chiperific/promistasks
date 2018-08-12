# frozen_string_literal: true

class CreateOrganizations < ActiveRecord::Migration[5.2]
  def change
    create_table :organizations do |t|
      t.string :name,   default: 'Family Promise GR'
      t.string :domain, default: 'familypromisegr.org'
      t.references :billing_contact,     references: :users, null: true
      t.references :maintenance_contact, references: :users, null: true
      t.references :volunteer_contact,   references: :users, null: true
    end
  end
end
