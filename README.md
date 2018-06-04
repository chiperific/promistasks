# Google Tasks API Extension for Family Promise GR

# To do:
1. Expect pending tests not to be pending
3. Relationships between users, properties and tasks
  - Make controllers
  - Set policies
4. Methodically interact with tasks
  - In the controllers
  - Need to capture responses to update record
5. Assign tasks to another user (who is authenticated)
  - User.tasklists should show creator && owner relationships (regardless of privacy?)
5. Properties are TaskLists
  - ****Show properties based upon related tasks' creator && owner status?****
  - Initialization Templates created when property created (default tasks)
  - Show a user these types of tasks:
    - Those assigned to the user
    - Those initialization_templates that match the user's type (creator && owner == property.creator)
      - task.initialization_template? && task.owner_type (is contained in) user.type (array)
5.1 When a user deletes a Tasklist in Google:
  - Catch that change and ...
5.2 When a user deletes a Tasklist in this app:
  - Provide the option to re-assign creator && owner? || actually 'discard' for all (delete through API for all users)
5.3 When a user deletes a Task in Google:
  - mark discarded_at
5.4 When a user discards at Task in this app:
  - delete in the Google (and make private = true?)

6. Get data from Google:
  - On a cron job? x times per day
  - On staff user login? Update just theirs or everyone's?
  - A hybrid: cron 2x per day (6 am & )
1. Destroy PropertyTracker

## Keep in mind
- PRIVATE properties must take self.tasks.map(&:owners &:creators) into account before removing
- PRIVATE properties shouldn't even be visible to RailsAdmin?
- Bring in tasklists and tasks from the app
- initialization_template tasks will use property.creator for task.creator && task.owner

## Someday
1. Test Clients in a meaningful way.

## Remind myself
1. rails secrets:edit
2. production backup / development restore-from production
3. "Your branch is n commits behind master" - git fetch origin
4. git remote prune origin --dry-run
5. Tasks API: https://developers.google.com/tasks/v1/reference/
6. OAuth2 Developer Playground: https://developers.google.com/oauthplayground
