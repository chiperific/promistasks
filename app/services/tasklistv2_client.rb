# frozen_string_literal: true

require 'google/apis/tasks_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'


OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'PromiseTasks Manager'.freeze
# Rails.application.secrets.google_client_id
# Rails.application.secrets.google_client_secret
SCOPE = Google::Apis::TasksV1::AUTH_TASKS

def authorize
  client_id = Rails.application.secrets.google_client_id
  # ...
end

