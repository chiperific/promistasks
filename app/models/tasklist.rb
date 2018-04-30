class Tasklist < ApplicationRecord

  def update_all_for(user)
    tasklists = TaskManager.new.list_tasklists(user)

    tasklists.each do |l|
      puts l
    end
  end
end
