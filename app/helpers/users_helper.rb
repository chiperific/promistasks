# frozen_string_literal: true

module UsersHelper
  def url_for_sync
    if url_for_sync_determiner
      sym = (request.env['HTTP_REFERER'] =~ /\?/).nil? ? '?' : '&'
      request.env['HTTP_REFERER'] + sym + 'syncing=true'
    else
      properties_path(syncing: true)
    end
  end

  def url_for_sync_determiner
    request.env['HTTP_REFERER'].present? &&
      request.env['HTTP_REFERER'] != request.env['REQUEST_URI'] &&
      request.env['REQUEST_URI'] != '/'
  end

  def show_alert(tasks, properties, payments, user)
    pulse_alert(tasks, properties, payments) ||
      amber(tasks, properties, payments) ||
      orange(tasks, properties, payments) ||
      green(tasks, properties, payments, user)
  end

  def alert_color(tasks, properties, payments)
    color = 'green'
    color = 'orange' if orange(tasks, properties, payments)
    color = 'amber' if amber(tasks, properties, payments)
    color = 'red' if pulse_alert(tasks, properties, payments)
    color
  end

  # color determinators:

  def pulse_alert(tasks, properties, payments) # red
    tasks.past_due.count.positive? ||
      properties.over_budget.length.positive? ||
      payments.past_due.length.positive?
  end

  def amber(tasks, properties, payments)
    tasks.due_within(7).count.positive? ||
      payments.due_within(7).count.positive?
  end

  def orange(tasks, properties, payments)
    properties.nearing_budget.length.positive? ||
      tasks.due_within(14).count.positive? ||
      payments.due_within(14).count.positive?
  end

  def green(tasks, properties, payments, user)
    tasks.created_since(user.last_sign_in_at).count.positive? ||
      tasks.needs_more_info.count.positive?
  end
end
