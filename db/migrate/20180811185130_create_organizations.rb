# frozen_string_literal: true

class CreateOrganizations < ActiveRecord::Migration[5.2]
  def change
    create_table :organizations do |t|
      t.string :name,          default: 'Family Promise GR',   null: false
      t.string :domain,        default: 'familypromisegr.org', null: false
      t.string :default_email, default: 'info@familypromisegr.org', null: false
      t.string :default_phone, default: '(616) 475-5220',      null: false
      t.references :billing_contact,     references: :users, null: true
      t.references :maintenance_contact, references: :users, null: true
      t.references :volunteer_contact,   references: :users, null: true
    end
  end
end
