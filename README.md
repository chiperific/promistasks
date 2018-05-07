# Testing Google Tasks API

# To do:
1. Test Devise w/ Omniauth (can I signup staff thru google && others through email&pw?)
1. Test TaskManager
  - https://github.com/intridea/omniauth/wiki/Integration-Testing
2. Save TaskLists and Tasks to the db
3. Methodically interact with tasks
4. Assign tasks to another user (who is authenticated)
4.1 Keep track of creator and assignee
4.2 Keep track of subject
5. Properties are TaskLists
5.1 Relationship between Task and Property (1 property has many tasks)
6. Get data from Google:
6.1 On a cron job? x times per day
6.2. On staff user login? Update just theirs or everyone's?
6.3 A hybrid: cron 2x per day (6 am & )
7. Create hybrid of this app and PropertyTracker

## Remind myself
1. rails secrets:edit
