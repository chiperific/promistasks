# Task and Resource Manager with Google Tasks API Extension for Family Promise GR

## To do:
6. Views:
  - Datatables doesn't play well with AJAXED tables. Use Datatable's AJAX instead of Rails
    -- Done for Tasks#index
    -- Where are the rest?
  - Vol / Contractor can't get past the homepage / task view
  - Lookup fields are still buggy (on tabbing?)
  - Suppress auto-fill: Connections#new / #edit

4. Controllers:
  - Contractors can't pick jobs (must be assigned as owner by a staff user)

## Decisions
- Footer: Anyone logged in can create a task
- Archiving property in app (when no open tasks) removes from GT.
  -- right now, for everybody (through the model)
  -- Tasks only archive for the user that clicks it (through controller)
  -- Seth should choose

## DEPLOY NOTES
- Deploy to heroku as a free app to start, then upgrade with a FPGR team CC
- Mailgun, right? taskmanager@familypromisegr.org
- From FPGR GSuite: https://console.developers.google.com/apis/dashboard
  - match redirect URI: https://tasks.familypromisegr.org/auth/google_oauth2/callback
  - if FPGR chooses something other than 'tasks.@', Rails.application.credentials.full_host will need to be updated
- Pay for SSL endpoints
  - Domains and certificates: https://dashboard.heroku.com/apps/promistasks/settings
- RESTRICT the oauth stuff in Devise

## FUTURE
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
8. Public features:
  - Task#public_index gets a slider for individual, group, both filtering
  - Task#public_index gets a filter-by-skill function

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
