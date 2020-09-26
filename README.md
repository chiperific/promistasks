# Task Manager with Google Tasks API Extension for Family Promise GR

## Wrecking ball
- Routes have been wrecked
- RSpec is deleted (do a find-all)
- Reinitialize testunit
- Models
- Controllers
- Views
- dB
- application_helper
- CONSTANTS is initiated somehwere
- jobs
- Use a new activejob queue adaptor: Resque or SideKiq

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
