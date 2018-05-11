# frozen_string_literal: true

module Constant
  class User
    EXT_TYPES = %w[Client Volunteer Contractor].freeze
    INT_TYPES = %w[Program Project Admin].freeze
    TYPES = %w[Program Project Admin Client Volunteer Contractor].freeze
  end

  class Task
    # TYPES = ['Work Order', 'Billing', 'To Do', 'Reminder'].freeze
    PRIORITY = %w[urgent high medium low someday].freeze
    ALERTS = ['due soon', 'urgent priority', 'high priority', 'data entry'].freeze
    OWNER_TYPES = ['Program Staff', 'Project Staff', 'Admin Staff'].freeze
    VISIBILITY = ['Staff', 'Public', 'Only associated people', 'Not clients'].freeze
    VISIBILITY_ENUM = [[0, 'Staff'], [1, 'Everyone'], [2, 'Only associated people'], [3, 'Not clients']].freeze
  end

  class Connection
    RELATIONSHIPS = ['tennant', 'landlord', 'staff contact', 'contractor', 'volunteer'].freeze
    STAGES = ['applied', 'approved', 'moved in'].freeze
  end
end
