# Task and Resource Manager with Google Tasks API Extension for Family Promise GR

## To do:
0. Javascript:
- syncing not visible when on `/properties/:id`?
-- And links are not replaced?

1. Property#tasks with $$
-- Report: show cost of associated tasks

2. Not syncing:
- make new Task in GT on existing list, click sync in app
- reassign a task from one user to another in PT, should show up on save in GT
- TasklistClient#handle_tasklist
- TasksClient#handle_task
- TasksClient#create_task

4. User#refresh_token! should return a custom error when OAuth fails.

5. Make sure tasks are archiving, not deleting

6. Views:
  - Datatables doesn't play well with AJAXED tables. Use Datatable's AJAX && Rails `.json.jbuilder` files
    -- Done for Tasks#index
    -- Where are the rest? (search for `$.ajax` calls)
  - Vol / Contractor can't get past the homepage / task view
  - Lookup fields are still buggy (on tabbing?)
  - Suppress auto-fill: Connections#new / #edit

4. Controllers:
  - Contractors can't pick jobs (must be assigned as owner by a staff user)

## Decisions
- Footer: Anyone logged in can create a task

## FUTURE
1. Use the Google Ruby API instead of HTTParty https://developers.google.com/tasks/quickstart/ruby
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
- if the above fails:
-- `rails db:reset`
-- `heroku pg:backups:capture -r production`
-- `heroku pg:backups:download -r production`
--`pg_restore --verbose --clean --no-acl --no-owner -h localhost -d promisetasks_dev latest.dump`
3. "Your branch is n commits behind master" - git fetch origin
4. git remote prune origin --dry-run
5. Tasks API: https://developers.google.com/tasks/v1/reference/
6. OAuth2 Developer Playground: https://developers.google.com/oauthplayground
7. API auth:
8. Pry: !!! exits pry unconditionally (alias of: exit-program)
9. Pry-remote:
  - Drop binding.remote_pry where desired;
  - app halts, but won't open an interactive session automatically
  - open an additional terminal session (i.e. a new shell)
  - enter pry-remote and the state is loaded
11. Mailer previews: http://localhost:3000/rails/mailers
