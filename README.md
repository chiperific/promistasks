# Task Manager with Google Tasks API Extension for Family Promise GR

## Overview
This organization uses Google Tasks to manage project tasks related to their mission of housing homeless families.

Many of the tasks are the same for every project.
So this app allows a user to create "auto tasks" that will automatically be added to any new Tasklist created in this app.

E.g.:
When Family Promise purchases a mobile home, they always need to take certain steps: perform an inspection, secure the title papers, check on the lot fees, setup utilties, etc.

By creating a Tasklist when a new property is aquired, this app can populate that Tasklist with the created "auto tasks".

This helps ensure all steps are taken everytime and saves on the hassle of having to manually recreate all these tasks on every tasklist.

## Capabilities:
1. User can sync this app to their Google Tasks
2. User can manage their Google Tasks in this app and have changes synced with Google
3. User can create new tasks in this app and have them pushed to Google
4. User can create "auto-tasks" to be automatically added to any new tasklist
5. User can set due dates ( + days in the future ) for auto-tasks
6. User can re-arrange the order of auto-tasks
7. Auto-tasks default to the top of the tasklist (then in order per #6)
8. A cron job handles syncing new Tasklists every hour during work days (since Google Tasks doesn't have any webhooks)
