# Google Tasks API Extension for Family Promise GR

# To do:
1.0 What happens when I log in with my 20Liters account (a second oauth user)?

1.2 Something is duplicating tasks on tasklists...changing owner, maybe?
  - Probably because I had api_delete commented out...
1.3 How to ignore duplicate tasks (same tasklist) from API?
  - Rely upon later update val?
1.4 Connections need to be editable && visible from Users and Properties
  - will need connection _form
1.5 Switch from pagination to tabs
  - https://materializecss.com/tabs.html
1.6 Public tasks should link to Task#info -- a public visible page w/ contact info (by owner? or org. general?)

1.8 When a new Property is created, default tasks are also generated:
  - From a fake seeds file?
  - What tasks?
  -- Get the title
  -- Inspect the property
  -- ...

2. Write system tests:
  - Every view
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
