# Google Tasks API Extension for Family Promise GR

## To do:
1. Models:
  - OrganizationData needed? For validations??
  - User: type stuff is nerfed, phone is required, address is gone, system_admin is now admin, User(when client) has adults and children
  - Property: has Park, expected_ & actual_, beds, baths, stage
  - Task: has volunteer_group, contractor, min_ & max_ & actual_, estimated_hours & actual_hours, delegate cost to payment?, has Payment
  - Connection: stage expansion
  - Park:
  - Utility:
  - Payment:
  - Park_user:

2. Model Tests:
  - Practically re-write

3. Service Tests:
  - Nerfed

4. Controllers:
  - Process changes from models
  - System sends email when new [Volunteer, Contractor, ] signs up
  - Reports
    - Date range filtering
  - Archiving property in app (when no open tasks) removes from GT.
  - Contractors can't pick jobs (must be assigned as owner by a staff user)
  - Creating a user tries to create a session?
  - When a new Property is created, default tasks are also generated:
    -- From a fake seeds file?
    -- What tasks?
    -- Get the title
    -- Inspect the property
    -- Setup utilities
  - When a user discards a Property in this app:
    -- Provide the option to re-assign each task's creator && owner? || actually 'discard' for all (delete through API for all users)
  - When a user discards at Task in this app:
    -- delete in Google

5. Services:
  - How to ignore duplicate tasks (same tasklist) from API?

6. Views:
  - Client reporting: public form with limited options for types of errors
  - Task#public mailto: link needs subject and body text
  - Task#user_finder user_table needs skills tabs in view
  - Vol / Contractor can't get past the homepage / task view
  - Lookup fields are still buggy (on tabbing?)
  - Suppress auto-fill: Connections#new / #edit
  - Rely upon later update val?

7. System tests:
  - Every view
    -- As sys_admin, staff, not_staff, client, not_logged_in
  - Every AJAX (use controllers to find)

8. Jobs
  - Get data from Google: On a cron job every hour

## Keep in mind
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
