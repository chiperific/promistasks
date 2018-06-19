# frozen_string_literal: true

FactoryBot.define do
  factory :tasklist_json, class: OpenStruct do
    kind 'tasks#taskList'
    sequence(:id) { |n| "FAKEmdQ5NTUwMTk3NjU1MjE3MTU6MDo#{n}" }
    sequence(:title) { |n| "JSON Factory tasklist #{n}" }
    updated '2018-05-16T02:51:39.000Z'
    sequence(:selfLink) { |n| "https://www.googleapis.com/tasks/v1/users/@me/lists/FAKEmdQ5NTUwMTk3NjU1MjE3MTU6MDo#{n}" }
  end

  factory :default_tasklist_json, class: OpenStruct do
    kind 'tasks#taskList'
    id 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow'
    title 'My Tasks'
    updated '2018-06-10T23:22:03.000Z'
    selfLink 'https://www.googleapis.com/tasks/v1/users/@me/lists/FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow'
  end

  factory :task_json, class: OpenStruct do
    kind 'tasks#task'
    sequence(:id) { |n| "fakeMDQ5NTUwMTk3NjU1MjE3MTU6MDozOTU2Nzc3NTgwNjE0NTM#{n}" }
    etag '"-7OFI3jKFsqNjDtcscX9ImH8hVU/MTA3NjIyMDI5Mg"'
    sequence(:title) { |n| "JSON Factory task #{n}" }
    notes 'Notes on json factory task'
    updated '2018-05-16T02:51:39.000Z'
    sequence(:selfLink) { |n| "https://www.googleapis.com/tasks/v1/lists/fakeMDQ5NTUwMTk3NjU1MjE3MTU6MDow/tasks/FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDoz#{n}" }
    position '00000000001261646641'
    status 'needsAction'
    due '2018-08-16T02:00:42.000Z'
  end

  factory :user_json, class: OpenStruct do
    access_token 'ya29.Gly7BRLVu0wJandalotlonger...'
    expires_in 3600
    id_token 'eyJhbGciOiJSUzI1NiIsIandalotlonger...'
    token_type 'Bearer'
  end
end
