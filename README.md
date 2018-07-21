# Google Tasks API Extension for Family Promise GR

# To do:
0 Default property show page

1.1 Finish User#show page
  - Include: 'Find public tasks that match skills': User#task_finder on: :model
  - Show tasks with skill needs that overlap with user's skill

1.7 Task#show - link to "Users with apropriate skills for this task..."
  - Match each one, prioritize list by # of matches.
  - E.g.: Task needs drywall, carpentry, painting; show users with all, then any

1.2 Something is duplicating tasks on tasklists...changing owner, maybe?
  - Probably because I had api_delete commented out...
1.3 How to ignore duplicate tasks (same tasklist) from API?
  - Rely upon later update val?
1.4 Connections need to be editable && visible from Users and Properties
  - will need connection _form
1.5 Switch from pagination to tabs
  - https://materializecss.com/tabs.html
1.6 Public tasks shouldn't go to Task#show

1.8 When a new Property is created, default tasks are also generated:
  - From a fake seeds file?
  - What tasks?
  -- Get the title
  -- Inspect the property
  -- ...

2. Write system tests:
  - Every view
  - Every AJAX (use controllers or policies to find)
3. Write model tests:
  - User has 2 pending methods
3.5 Re-write services tests -- because I nerfed them both
4. Methodically interact with the API
  - Accepting and syncing works through Task(list)sClient
  - What about pushing and syncing?
  - What about two users? Expecting some real shit to occur

5. Properties are TaskLists
5.1 When a user deletes a Tasklist in Google: do nothing to the app (force_recreate)
5.2 When a user discards a Property in this app:
  - Provide the option to re-assign each task's creator && owner? || actually 'discard' for all (delete through API for all users)
5.3 When a user deletes a Task in Google:
  - do nothing (force_recreate) ("completion isn't optional")
5.4 When a user discards at Task in this app:
  - delete in Google

6. Get data from Google:
  - On a cron job every hour
  - On staff user login. Update everything in the background (delayed_job)

## Keep in mind
- PRIVATE properties must take self.tasks.map(&:owners &:creators) into account before removing
- Bring in tasklists and tasks from the app on sign_in(user)
- initialization_template tasks will use property.creator for task.creator && task.owner

## Someday
1. Test Clients in a meaningful way.
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
