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
    TASKLIST = %r{https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}}
    TASK = %r{https:\/\/www.googleapis.com\/tasks\/v1\/lists\/.{0,245}}
  end
end
