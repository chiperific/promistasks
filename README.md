# Google Tasks API Extension for Family Promise GR

# To do:
3. Relationships between users, properties and tasks
  - Set policies
  - How to allow users to have private tasklists? Don't propegate certain tasklists
4. Methodically interact with tasks
  - In the controller?
  - Need to capture responses to update record
5. Assign tasks to another user (who is authenticated)
  - Keep track of creator and owner
  - Keep track of subject
5. Properties are TaskLists
  - Initialization Templates created when property created (default tasks)
  - Initialization Templates need a "system user" for creator / owner
  - Show a user these types of tasks:
    - Those assigned to the user
    - Those assigned to the "system" that match the user's type
      - task.initialization_template? && task.owner_type (is contained in) user.type (array)
5.1 When a user deletes a Tasklist in Google:
  - Catch that change and add a record to ExcludePropertyUser
5.2 When a user deletes a Tasklist in this app:
  - Provide the option to a record to ExcludePropertyUser (delete through API for current_user) || actually 'discard' for all (delete through API for all users)
6. Get data from Google:
  - On a cron job? x times per day
  - On staff user login? Update just theirs or everyone's?
  - A hybrid: cron 2x per day (6 am & )
1. Destroy PropertyTracker

## Someday
1. Test Clients in a meaningful way.

## Remind myself
1. rails secrets:edit
2. production backup / development restore-from production
3. "Your branch is n commits behind master" - git fetch origin
4. git remote prune origin --dry-run
5. Tasks API: https://developers.google.com/tasks/v1/reference/
6. OAuth2 Developer Playground: https://developers.google.com/oauthplayground
