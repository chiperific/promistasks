# frozen_string_literal: true

module Constant
  class Connection
    RELATIONSHIPS = ['tennant', 'staff contact', 'contractor', 'volunteer'].freeze
    STAGES = ['applied', 'approved', 'moved in', 'initial walkthrough', 'final walkthrough', 'transferred title', 'vacated', 'returned property'].freeze
  end

  class Params
    ACTIONS = %w[alerts api_sync
                 clear_completed_jobs complete create current_user_id
                 destroy default
                 edit
                 find_id_by_name
                 google_oauth2
                 new
                 owner_enum
                 property_enum
                 skills subject_enum
                 tasks_filter
                 un_complete users update update_skills update_tasks update_users].freeze
  end

  class Payment
    METHODS = %w[ACH auto-pay cash check credit].freeze
  end

  class Property
    STAGES = %w[acquired construction finishing complete].freeze
  end

  class Regex
    TASK =             %r{https:\/\/www.googleapis.com\/tasks\/v1\/lists\/.{0,245}}
    LIST_TASKS =       %r{https:\/\/www.googleapis.com\/tasks\/v1\/lists\/.{0,245}\/tasks(\/||)$}
    TASKLIST =         %r{https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/($|[^@].{0,130})}
    LIST_TASKLISTS =   %r{https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists$}
    DEFAULT_TASKLIST = %r{https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/@default$}
    STATIC_MAP =       %r{https:\/\/maps.googleapis.com\/maps\/api\/staticmap\?key=.{1,20}&size=.{1,4}x.{1,4}&zoom=.{1,2}&markers=color:blue%7C.{1,20}}
    GEOCODE =          %r{https:\/\/maps.googleapis.com\/maps\/api\/geocode\/json\?address=.{1,100}&key=.{1,40}&language=en&sensor=false}
  end

  class Task
    STATUS = %w[needsAction completed].freeze
    PRIORITY = %w[urgent high medium low someday].freeze
    PRIORITY_ENUM = [['urgent', 0], ['high', 1], ['medium', 2], ['low', 3], ['someday', 4]].freeze
    VISIBILITY = ['Staff', 'Public', 'Only associated people', 'Not clients'].freeze
    VISIBILITY_ENUM = [['Staff', 0], ['Everyone', 1], ['Only associated people', 2], ['Not clients', 3]].freeze
  end

  class TaskUser
    SCOPE = %w[creator owner both].freeze
  end

  class User
    TYPES = %w[Staff Client Volunteer Contractor].freeze
  end

  class Utility
    TYPES = %w[gas electric water garbage sewer cable internet phone].freeze
  end
end
