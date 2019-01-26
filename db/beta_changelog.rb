# frozen_string_literal: true

# Things that changed

table 'connections' do
t.string 'stage' # extra options
end

table 'organizations' do
t.string 'name', default: 'Family Promise GR', null: false
t.string 'domain', default: 'familypromisegr.org', null: false
t.string 'default_staff_phone', default: '(616) 475-5220', null: false
t.bigint 'billing_contact_id'
t.bigint 'maintenance_contact_id'
t.bigint 'volunteer_contact_id'
end

table 'park_users' do
t.bigint 'park_id', null: false
t.bigint 'user_id', null: false
t.string 'relationship', null: false
t.datetime 'created_at', null: false
t.datetime 'updated_at', null: false
end

table 'parks' do
t.string 'name', null: false
t.string 'address'
t.string 'city'
t.string 'state', default: 'MI'
t.string 'postal_code'
t.text 'notes'
t.string 'poc_name'
t.string 'poc_email'
t.string 'poc_phone'
t.datetime 'discarded_at'
t.float 'latitude'
t.float 'longitude'
t.datetime 'created_at', null: false
t.datetime 'updated_at', null: false
end

table 'payments' do
t.bigint 'property_id'
t.bigint 'park_id'
t.bigint 'utility_id'
t.bigint 'task_id'
t.bigint 'contractor_id'
t.bigint 'client_id'
t.string 'utility_type'
t.string 'utility_account'
t.date 'utility_service_started'
t.text 'notes'
t.integer 'bill_amt_cents', default: 0, null: false
t.string 'bill_amt_currency', default: 'USD', null: false
t.integer 'payment_amt_cents'
t.string 'payment_amt_currency', default: 'USD', null: false
t.string 'method'
t.date 'received'
t.date 'due'
t.date 'paid'
t.text 'recurrence'
t.boolean 'recurring', default: false, null: false
t.boolean 'send_email_reminders', default: false, null: false
t.boolean 'suppress_system_alerts', default: false, null: false
t.datetime 'discarded_at'
t.bigint 'creator_id', null: false
t.datetime 'created_at', null: false
t.datetime 'updated_at', null: false
end

table 'properties' do
t.bigint 'park_id'
t.string 'stage', default: 'acquired'
t.date 'expected_completion_date'
t.date 'actual_completion_date'
t.integer 'beds', default: 1, null: false
t.integer 'baths', default: 1, null: false
end

table 'task_users' do
t.string 'scope', null: false
end

table 'tasks' do
removed: position, position_num, parent, previous
t.boolean 'volunteer_group', default: false, null: false
t.boolean 'professional', default: false, null: false
t.integer 'min_volunteers', default: 0, null: false
t.integer 'max_volunteers', default: 0, null: false
t.integer 'actual_volunteers'
t.float 'estimated_hours'
t.float 'actual_hours'
end

table "users"do
removed: program_staff, admin_staff, project_staff
t.boolean "staff", default: false, null: false
t.integer "adults", default: 1, null: false
t.integer "children", default: 0, null: false
end

table 'utilities' do
t.string 'name', null: false
t.text 'notes'
t.string 'address'
t.string 'city'
t.string 'state', default: 'MI'
t.string 'postal_code'
t.string 'poc_name'
t.string 'poc_email'
t.string 'poc_phone'
t.datetime 'discarded_at'
t.float 'latitude'
t.float 'longitude'
t.datetime 'created_at', null: false
t.datetime 'updated_at', null: false
end
