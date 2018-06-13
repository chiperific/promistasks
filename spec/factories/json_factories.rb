# frozen_string_literal: true

FactoryBot.define do
  factory :tasklist_json, class: OpenStruct do
    kind 'tasks#taskList'
    sequence(:id) { |n| "FAKEmdQ5NTUwMTk3NjU1MjE3MTU6MDo#{n}" }
    sequence(:title) { |n| "JSON Factory tasklist #{n}" }
    updated '2018-05-16T02:51:39.000Z'
    sequence(:selfLink) { |n| "https://www.googleapis.com/tasks/v1/users/@me/lists/MDE1MDQ5NTUwMTk3NjU1MjE3MTU6MDo#{n}" }
  end

  factory :task_json, class: OpenStruct do
    kind 'tasks#task'
    sequence(:id) { |n| "fakeMDQ5NTUwMTk3NjU1MjE3MTU6MDozOTU2Nzc3NTgwNjE0NTM#{n}" }
    etag '"-7OFI3jKFsqNjDtcscX9ImH8hVU/MTA3NjIyMDI5Mg"'
    sequence(:title) { |n| "JSON Factory task #{n}" }
    notes 'Notes on json factory task'
    updated '2018-05-16T02:51:39.000Z'
    sequence(:selfLink) { |n| "https://www.googleapis.com/tasks/v1/lists/MDE1MDQ5NTUwMTk3NjU1MjE3MTU6MDow/tasks/MDE1MDQ5NTUwMTk3NjU1MjE3MTU6MDoz#{n}" }
    position '00000000001261646641'
    status 'needsAction'
    due '2018-08-16T02:00:42.000Z'
  end
end
