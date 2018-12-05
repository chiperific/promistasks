# Task and Resource Manager with Google Tasks API Extension for Family Promise GR

## To do:
4. Controllers:
  - Users#show needs payments table
  - Users#show #connections needs Parks table
  - Alerts needs payment reminders
  - System sends email when new non-oauth signs up
  - System sends email when payment is due

  - Reports
    - Date range filtering
  - Archiving property in app (when no open tasks) removes from GT.
  - Contractors can't pick jobs (must be assigned as owner by a staff user)
  - Creating a user tries to create a session?
  - When a new Property is created, default tasks are also generated:
    -- From a fake seeds file?
    -- What tasks:
      + Get the title
      + Inspect the property
      + Setup utilities
    -- Assign based upon Organization#{apropriate}_contact
  - When a user discards a Property in this app:
    -- Provide the option to re-assign each task's creator && owner? || actually 'discard' for all (delete through API for all users)
  - When a user discards at Task in this app:
    -- delete in Google
  - Show an alert when a Property.stage != 'complete' && Property.expected_completion_date within 7 days?
  - Task now has lots of volunteer/contractor fields. Integrate these into #public views
    -- Professional boolean indicates a specific skill is needed. Should this affect visibility or just have some flag on public view?
  - Task#public gets a slider for individual, group, both filtering
  - Task#public gets a filter-by-skill function
  - Task: delegate cost to payment?

5. Services:
  - How to ignore duplicate tasks (same tasklist) from API?

6. Views:
  - Client reporting: public form with limited options for types of errors
    -- Looks up property by client
    -- creates a task for property.connections.where(relationship: 'staff contact').last || Organization.maintenance_contact
    -- Sends an email alert to the owner.
  - Task#public mailto: link needs subject and body text
  - Task#user_finder user_table needs skills tabs in view
  - Vol / Contractor can't get past the homepage / task view
  - Lookup fields are still buggy (on tabbing?)
  - Suppress auto-fill: Connections#new / #edit
  - Rely upon later update val?

8. Jobs
  - Get data from Google: On a cron job every hour

9. Mailers (need tests)
  - System sends email when new && non-oauth signs up
  - System sends email with list of payments due between 14 and 0 days && past due
  - Client Reports send an email when created

## Decisions
- Footer: Anyone logged in can create a task

## Keep in mind
- System Spec Naming convention:
  * create = #new
  * edit = #edit
  * show = #show
  * view = #index
- Could do a progress bar on property show, related to Property#occupancy_status: *--*--*--*
- PRIVATE properties must take self.tasks.map(&:owners &:creators) into account before removing

## Someday
1. Use the Google Ruby API instead of HTTParty
2. Application model: client && property
3. Maintenance request model: client && property

## Remind myself
1. rails secrets:edit
2. production backup / development restore-from production
3. "Your branch is n commits behind master" - git fetch origin
4. git remote prune origin --dry-run
5. Tasks API: https://developers.google.com/tasks/v1/reference/
6. OAuth2 Developer Playground: https://developers.google.com/oauthplayground
7. API auth: https://console.developers.google.com/apis/dashboard?project=tasks-api-202522
8. Pry: !!! exits pry unconditionally (alias of: exit-program)
9. Pry-remote:
  - Drop binding.remote_pry where desired;
  - app halts, but won't open an interactive session automatically
  - open an additional terminal session (i.e. a new shell)
  - enter pry-remote and the state is loaded
10. IceCube date recurrences: https://github.com/seejohnrun/ice_cube
11. Mailer previews: http://localhost:3000/rails/mailers

## Slowest examples (33.66 seconds, 8.6% of total time):
* Property limits records by scope #over_budget
  - 3.96 seconds ./spec/models/property_spec.rb:127
* Property limits records by scope #nearing_budget
  - 3.79 seconds ./spec/models/property_spec.rb:135
* Property limits record by class method scopes: self.pending returns active properties where occupancy_status == pending application
  - 3.63 seconds ./spec/models/property_spec.rb:191
* Connection#relationship_must_match_user_type ensures the user type and relationship are in sync
  - 3.15 seconds ./spec/models/connection_spec.rb:172
* TaskUser must be valid against the schema in order to save
  - 2.97 seconds ./spec/models/task_user_spec.rb:24
* TaskUser must be valid against the model in order to save
  - 2.95 seconds ./spec/models/task_user_spec.rb:38
* Property limits records by scope #needs_title returns only records without a certificate_number
  - 2.77 seconds ./spec/models/property_spec.rb:83
* Property limits records by scope #active is alias of #kept
  - 2.67 seconds ./spec/models/property_spec.rb:147
* Property limits records by scope #visible_to returns a combo of #created_by, #with_tasks_for, and #public_visible
  - 2.62 seconds ./spec/models/property_spec.rb:118
