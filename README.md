# Google Tasks API Extension for Family Promise GR

## What's still needed:
  +- Payments has billing feature to alert upcoming
    +- Recurrence sing IceCube::Schedule
    -- Creates a dup for the next payment date automatically
    -- Emails the billing_contact X days before due if payment type != 'auto-pay'
  +- Tasks# Vols needed, vols used, hours
  +- Model: +Parks have many properties, +users can be associated with a park
  +- Staff: phone required
  +- User: Kill: Phone2, Address, program_staff, project_staff, admin_staff (type is not polymorphic, only [staff, volunteer, contractor, client])
  +- Reordering tasks: delete position, position_int, parent_id, previous_id from Task and task.move function)
  - System sends email when new [Volunteer, Contractor, ] signs up
  - Reports
    - Date range filtering
  - Test suite
  - Archiving property in app (when no open tasks) removes from GT.
  - Client reporting: public form with limited options for types of errors
  - Task#public mailto: link needs subject and body text
  - Contractors can't pick jobs (must be assigned as owner by a staff user)
  - Task#user_finder user_table needs skills tabs in view
  - Vol / Contractor can't get past the homepage / task view
  - Lookup fileds are still buggy (on tabbing?)

## To do:
1.0 Suppress auto-fill: Connections#new / #edit
1.1 Creating a user tries to create a session
1.3 How to ignore duplicate tasks (same tasklist) from API?
  - Rely upon later update val?
1.8 When a new Property is created, default tasks are also generated:
  - From a fake seeds file?
  - What tasks?
  -- Get the title
  -- Inspect the property
  -- Setup utilities

2. Write tests:
  - Models are practically all nerfed
  - Every view
  -- As sys_admin, staff, not_staff, client, not_logged_in
  - Every AJAX (use controllers to find)
3. Write model tests:
  - User has 2 pending methods
3.5 Re-write services tests -- because I nerfed them both
4. Methodically interact with the API
  - Accepting and syncing works through Task(list)sClient
  - What about pushing and syncing?
  - What about two users? Expecting some real shit to occur

5. Properties are TaskLists
5.2 When a user discards a Property in this app:
  - Provide the option to re-assign each task's creator && owner? || actually 'discard' for all (delete through API for all users)
5.4 When a user discards at Task in this app:
  - delete in Google

6. Get data from Google:
  - On a cron job every hour

## Keep in mind
- PRIVATE properties must take self.tasks.map(&:owners &:creators) into account before removing

## Someday
2. Use the Google Ruby API instead of HTTParty

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
