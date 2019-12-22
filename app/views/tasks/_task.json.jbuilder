# frozen_string_literal: true

json.notice task.needs_more_info? ? '<span class="btn-floating btn-small red lighten-2"><i class="material-icons tooltipped" data-position="bottom" data-tooltip="Needs more info!">error_outline</i></span>' : '&nbsp'
if task.priority.present?
  json.priority '<span class="new badge <%= task.priority_color %> white-text" data-badge-caption="">' + Constant::Task::PRIORITY[task.priority] + '</span>'
else
  json.priority '<p class="small-text">not set</p>'
end
json.title task.snipped_title(30)
json.assigned_to current_user.staff? ? link_to(task.owner.name, user_path(task.owner)) : task.owner.name
unless controller_name == 'properties'
  json.property task.property.visible_to?(current_user) ? link_to(task.property.name, property_path(task.property)) : task.property.name
end
task_due = task.due || 'not set'
if task.past_due?
  json.due '<span class="new badge red lighten-2 white-text" data-badge-caption="">' + human_date(task.due) + '</span>'
elsif task.due.present?
  json.due '<span class="new badge green lighten-2 white-text" data-badge-caption="">' + human_date(task.due) + '</span>'
else
  json.due '<span class="small-text">' + task_due + '</span>'
end
task_budget = humanized_money_with_symbol(task.budget) || '<span class="small-text">not set</span>'
task_cost = humanized_money_with_symbol(task.cost) || '<span class="small-text">not set</span>'
if controller_name == 'properties'
  json.budget task_budget
  json.cost task_cost
end
unless controller.action_name == 'tasks_finder'
  task_complete = task.complete? ? 'checked' : ''
  if task.active? && task.budget_cents.present? && task.cost_cents.blank?
    json.completion '<span class="small-text">needs cost</span>'
  else
    json.completion '<label><input type="checkbox" class="filled-in complete_bool" ' + task_complete + '><span class="complete_span">&nbsp;</span><span class="task_id">' + task.id.to_s + '</span></label>'
  end
end
json.show link_to '<i class="material-icons">arrow_forward</i>'.html_safe, task_path(task), class: 'btn-floating btn-small green'
json.edit link_to '<i class="material-icons">edit</i>'.html_safe, edit_task_path(task), class: 'btn-floating btn-small blue darken-2', 'data-turbolinks' => 'false'
