web: bundle exec puma -p 3000 -C config/puma.rb
worker: rake send_reminders && rake jobs:work
