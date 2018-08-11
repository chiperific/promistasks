# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[5.2]
  def change
    create_table :payments do |t|
      t.references :property,   foreign_key: true
      t.references :park,       foreign_key: true
      t.references :utility,    foreign_key: true
      t.references :contractor, references: :users
      t.references :client,     references: :users
      t.string :utility_type # use Constant::Utility::TYPES
      t.string :utility_account
      t.date :utility_service_started
      t.text :notes
      t.monetize :bill_amt,    amount: { null: false }
      t.monetize :payment_amt, amount: { null: true, default: nil }
      t.string :method # use Constant::Payment::METHODS
      t.date :received
      t.date :due
      t.date :paid
      t.boolean :recurring, null: false, default: false
      t.text :recurrence # YAML from IceCube::Schedule
      t.boolean :send_email_reminders, null: false, default: false
      t.boolean :suppress_system_alerts, null: false, default: false
      t.datetime :discarded_at
      t.references :creator, references: :users, null: false
      t.timestamps
    end
  end
end
