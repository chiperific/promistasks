# Task Manager with Google Tasks API Extension for Family Promise GR

## Wrecking ball
- Routes have been wrecked
- matches tempapp: ~/; ~/vendor; ~/tmp; ~/test; ~/script; ~/public; ~/log; ~/lib; ~/config; ~/bin
- RSpec is deleted (do a find-all)
- Reinitialized testunit
- Eliminate Devise. Just use OmniAuth
- Models have been wrecked
- Policies have been wrecked
- Controllers have been wrecked
- Views have been wrecked
- dB has been wrecked
- jobs have been wrecked
- Use a new activejob queue adaptor: Resque or SideKiq
- Mailgun still has settings.
- Use HAML instead of ERB, as long as can compat with MaterializeSCSS

## Whiteboard:
1. User can login with Google Oauth
2. Google API Client controls access to Tasks API
3. dB stores as little info as possible
4. User can set tasks to be automatically added to any new tasklist
5. User can set due dates ( + days in the future ) for auto-tasks
6. User can re-arrange the order of auto-tasks
  - Which live-updates Google Tasks
7. Auto-tasks default to the top of the tasklist (then in order per #6)
8. A cron job checks for new tasklists every 1 hour during business hours


## Remind myself
1. rails credentials:edit
2. production backup / development restore-from production
- if the above fails:
-- `rails db:reset`
-- `heroku pg:backups:capture -r production`
-- `heroku pg:backups:download -r production`
--`pg_restore --verbose --clean --no-acl --no-owner -h localhost -d promisetasks_dev latest.dump`
3. "Your branch is n commits behind master" - git fetch origin
4. git remote prune origin --dry-run
5. API Console: https://console.developers.google.com/apis/credentials?project=pihtasks
5. Tasks API: https://developers.google.com/tasks/v1/reference/
6. OAuth2 Developer Playground: https://developers.google.com/oauthplayground
7. API auth:
8. Pry: !!! exits pry unconditionally (alias of: exit-program)
9. Pry-remote:
  - Drop binding.remote_pry where desired;
  - app halts, but won't open an interactive session automatically
  - open an additional terminal session (i.e. a new shell)
  - enter pry-remote and the state is loaded
11. Mailer previews: http://localhost:3000/rails/mailers
