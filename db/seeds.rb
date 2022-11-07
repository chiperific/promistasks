# frozen_string_literal: true

User.create(
  [
    { name: 'Seth C.', email: 'seth@familypromisegr.org' }
  ]
)

AutoTask.create(
  [
    { title: 'Get the title', notes: 'Call Karen at the County: 616-256-7711', days_until_due: 10, user_id: 1 },
    { title: 'Perform an inspection', days_until_due: 30, user_id: 1 },
    { title: 'Make first payment to Park', days_until_due: 15, user_id: 1 },
    { title: 'Setup utilities', notes: 'Gas, water, electricity, trash, recycling', days_until_due: 30, user_id: 1 },
    { title: 'Give budget to Kathy', notes: 'Needs 6 months of lot rent plus utilities', days_until_due: 30, user_id: 1 }
  ]
)
