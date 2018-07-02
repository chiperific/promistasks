# frozen_string_literal: true

module UsersHelper
  def url_for_sync
    if request.env['HTTP_REFERER'].present? &&
       request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
      request.env['HTTP_REFERER'] + '?syncing=true'
    else
      properties_path(syncing: true)
    end
  end

  def pulse_alert(tasks, properties)
    tasks.past_due.count.positive? ||
      properties.over_budget.length.positive? ||
      properties.nearing_budget.length.positive?
  end

  def show_alert(tasks, properties, user)
    pulse_alert(tasks, properties) ||
      tasks.due_within(7).count.positive? ||
      tasks.needs_more_info.count.positive? ||
      tasks.due_within(14).count.positive? ||
      tasks.created_since(user.last_sign_in_at).count.positive?
  end

  def alert_color(tasks, properties)
    color = 'green'
    color = 'yellow' if tasks.needs_more_info.count.positive?
    color = 'amber' if tasks.due_within(7).count.positive?
    color = 'red' if pulse_alert(tasks, properties)
    color
  end
end
