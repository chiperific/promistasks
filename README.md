# Google Tasks API Extension for Family Promise GR

# To do:
1. Setup Circle CI
1. Test TaskManager
  - only getting lists is working
  - https://github.com/intridea/omniauth/wiki/Integration-Testing
2. Relationships between users, properties and tasks
3. Methodically interact with tasks
4. Assign tasks to another user (who is authenticated)
4.1 Keep track of creator and assignee
4.2 Keep track of subject
5. Properties are TaskLists
  - Initialization Templates created when property created (default tasks)
  - Initialization Templates need a "system user" for creator / owner
  - Show a user two types of tasks:
    - Those assigned to the user
    - Those assigned to the "system" that match the user's type
      - task.initialization_template? && task.owner_type (is contained in) user.type (array)
5.1 Relationship between Task and Property (1 property has many tasks)
6. Get data from Google:
6.1 On a cron job? x times per day
6.2. On staff user login? Update just theirs or everyone's?
6.3 A hybrid: cron 2x per day (6 am & )
7. Create hybrid of this app and PropertyTracker
1. Destroy PropertyTracker

## Remind myself
1. rails secrets:edit
2. production backup / development restore-from production
  - User.all.each do |u| u.update(password: "password", password_confirmation: "password") end
3. "Your branch is n commits behind master" - git fetch origin
4. git remote prune origin --dry-run
5. Tasks API: https://developers.google.com/tasks/v1/reference/
