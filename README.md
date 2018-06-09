# Google Tasks API Extension for Family Promise GR

# To do:
1. Schema change: task_users.deleted, task_users.completed_at, task.deleted
  - Need spec adjustments
1. Expect pending tests not to be pending
3. Relationships between users, properties and tasks
  - Make controllers
  - Set policies
4. Methodically interact with the API
  - Through the models
5. Assign tasks to another user (who is authenticated)
  - User.tasklists should show creator && owner relationships (regardless of property.is_private )
5. Properties are TaskLists
  - ****Show properties based upon related tasks' creator && owner status?****
  - Initialization Templates created when property created (default tasks)
  - Show a user these types of tasks:
    - Those assigned to the user
    - Those initialization_templates that match the user's type (creator && owner == property.creator)
      - task.initialization_template? && task.owner_type (is contained in) user.type (array)
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
1. Destroy PropertyTracker

## Keep in mind
- PRIVATE properties must take self.tasks.map(&:owners &:creators) into account before removing
- Bring in tasklists and tasks from the app on user.create
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
