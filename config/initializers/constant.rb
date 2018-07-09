# frozen_string_literal: true

module Constant
  class User
    EXT_TYPES = %w[Client Volunteer Contractor].freeze
    INT_TYPES = %w[Program Project Admin].freeze
    TYPES = %w[Program Project Admin Client Volunteer Contractor].freeze
  end

  class Task
    STATUS = %w[needsAction completed].freeze
    PRIORITY = %w[urgent high medium low someday].freeze
    ALERTS = ['due soon', 'urgent priority', 'high priority', 'data entry'].freeze
    OWNER_TYPES = ['Program Staff', 'Project Staff', 'Admin Staff'].freeze
    VISIBILITY = ['Staff', 'Public', 'Only associated people', 'Not clients'].freeze
    VISIBILITY_ENUM = [[0, 'Staff'], [1, 'Everyone'], [2, 'Only associated people'], [3, 'Not clients']].freeze
  end

  class Connection
    RELATIONSHIPS = ['tennant', 'staff contact', 'contractor', 'volunteer'].freeze
    STAGES = ['applied', 'approved', 'moved in'].freeze
  end

  class Regex
    TASK =             %r{https:\/\/www.googleapis.com\/tasks\/v1\/lists\/.{0,245}}
    LIST_TASKS =       %r{https:\/\/www.googleapis.com\/tasks\/v1\/lists\/.{0,245}\/tasks(\/||)$}
    TASKLIST =         %r{https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/($|[^@].{0,130})}
    LIST_TASKLISTS =   %r{https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists$}
    DEFAULT_TASKLIST = %r{https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/@default$}
    STATIC_MAP =       %r{https:\/\/maps.googleapis.com\/maps\/api\/staticmap\?key=.{1,20}&size=.{1,4}x.{1,4}&zoom=.{1,2}&markers=color:blue%7C.{1,20}}
    STREET_MAP =       %r{https:\/\/maps.googleapis.com\/maps\/api\/streetview\?key=.{1,20}&location=.{1,20},.{1,20}&size=.{1,4}x.{1,4}}
    GEOCODE =          %r{https:\/\/maps.googleapis.com\/maps\/api\/geocode\/json\?address=.{1,40}&key=.{1,40}&language=en&sensor=false}
  end

  class Params
    ACTIONS = %w[alerts api_sync clear_completed_jobs current_user_id destroy edit google_oauth2 new].freeze
  end
end
