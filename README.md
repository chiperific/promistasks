# Task Manager with Google Tasks API Extension for Family Promise GR

## Construction Crew
- Scenario: Tasklist deleted in Google, still exists in app:
-- Needs to be removed from app

- Mailgun still has settings

- Bother writing tests?

## Whiteboard:
4. √ User can set tasks to be automatically added to any new tasklist
5. √ User can set due dates ( + days in the future ) for auto-tasks
6. √ User can re-arrange the order of auto-tasks
7. √ Auto-tasks default to the top of the tasklist (then in order per #6)
8. A cron job handles new Tasklists every hour during work days


## Remind myself
2. production backup / development restore-from production
3. "Your branch is n commits behind master" - git fetch origin
4. git remote prune origin --dry-run
5. API Console: https://console.developers.google.com/apis/credentials?project=pihtasks
5. Tasks API: https://googleapis.dev/ruby/google-api-client/latest/Google/Apis/TasksV1.html
6. Materialize: https://materializecss.com/
