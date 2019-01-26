# Task and Resource Manager with Google Tasks API Extension for Family Promise GR

## To do:
6. Views:
  - Datatables doesn't play well with AJAXED tables. Use Datatable's AJAX instead of Rails
    -- Done for Tasks#index
    -- Where are the rest?
  - Task#public mailto: link needs subject and body text
  - Task#user_finder user_table needs skills tabs in view
  - Vol / Contractor can't get past the homepage / task view
  - Lookup fields are still buggy (on tabbing?)
  - Suppress auto-fill: Connections#new / #edit
  - Rely upon later update val?

4. Controllers:
  - Contractors can't pick jobs (must be assigned as owner by a staff user)
  - When a new Property is created, default tasks are also generated:
    -- From a fake seeds file?
      + Get the title
      + Inspect the property
      + Setup utilities
    -- Assign based upon Organization#{apropriate}_contact
  - Show an alert when a Property.stage != 'complete' && Property.expected_completion_date within 7 days?
  - Task now has lots of volunteer/contractor fields. Integrate these into #public views
    -- Professional boolean indicates a specific skill is needed. Should this affect visibility or just have some flag on public view?
  - Task#public gets a slider for individual, group, both filtering
  - Task#public gets a filter-by-skill function

9. Mailers (need tests)
  - System sends email when new && non-oauth signs up
  - System sends email with list of payments due between 14 and 0 days && past due
  - Client Reports send an email when created

## FUTURE


## Decisions
- Footer: Anyone logged in can create a task
- Archiving property in app (when no open tasks) removes from GT.
  -- right now, for everybody (through the model)
  -- Tasks only archive for the user that clicks it (through controller)
  -- Seth should choose

## DEPLOY NOTES
- Deploy to heroku as a free app to start, then upgrade with a FPGR team aCC
  -- put my secrets in heroku: $ heroku config:set RAILS_MASTER_KEY=`cat config/master.key`https://medium.com/craft-academy/encrypted-credentials-in-ruby-on-rails-9db1f36d8570
- Mailgun, right? taskmanager@familypromisegr.org
- From FPGR GSuite: https://console.developers.google.com/apis/dashboard
- Pay for SSL endpoints


## Someday
1. Use the Google Ruby API instead of HTTParty
2. Application model: client && property
3. Maintenance request model: client && property public form with limited options for types of errors
  - Looks up property by client
  - creates a task for property.connections.where(relationship: 'staff contact').last || Organization.maintenance_contact
  - Sends an email alert to the owner.
5. Services:
  - How to ignore duplicate tasks (same tasklist) from API?
6. Property#show
  - Could do a progress bar on property show, related to Property#occupancy_status: *--*--*--*
7. Private Properties
  - must take self.tasks.map(&:owners &:creators) into account before removing

## Remind myself
1. rails credentials:edit
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
11. Mailer previews: http://localhost:3000/rails/mailers
