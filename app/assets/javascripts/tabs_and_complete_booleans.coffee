dttbAjaxTrigger = (filter, table) ->
  uri = '/tasks.json?filter=' + filter
  table.ajax.url(uri).load( (json) ->
    reInitTooltips()
  )

reInitTooltips = ->
  tooltips = $('.tooltipped')
  M.Tooltip.init(tooltips, {
  'enterDelay': 800
  })

$(document).on 'turbolinks:load', ->
  return unless controllerMatches(
    ['tasks', 'properties', 'users', 'connections', 'parks']
  ) && actionMatches(
    ['show', 'index', 'tasks', 'list']
  )

  # Don't initiate this in global
  # because then the JS indicator (non-CSS bottom border)
  # appears on the initial active element
  tabs = $('.tabs')
  M.Tabs.init(tabs)

  # This allows for `/tasks?filter=all` redirects, e.g. from notifications
  if getParameterByName('filter') != null
    target = document.location.search.replace('?filter=','')
    scope = $('ul.tabs').attr('name')
    attrSelector = 'ul[name="' + scope + '"]'
    anchors = $(attrSelector).find('a')
    anchors.removeClass('active')
    targetID = 'a#' + scope + '_' + target
    $(targetID).addClass('active')

  # AJAX to auto-complete or un-complete a task
  $('#task_table_body').on 'click', 'input.complete_bool', ->
    checked = $(this).prop('checked')
    if checked == true
      action = '/complete'
      msg = 'Marked complete!'
    else
      action = '/un_complete'
      msg = 'Removed completion.'

    taskId = $(this).siblings('.task_id').text().trim()
    location = '/tasks/' + taskId + action
    $.ajax(url: location).done (response) ->
      # once the task is changed:
      M.toast({html: msg})
      # trigger the datatable AJAX so the changed task is removed from view
      filter = $('a.active').attr('data-filter')
      table = $('#task_table').DataTable()
      dttbAjaxTrigger(filter, table)
      true
    true
  true

