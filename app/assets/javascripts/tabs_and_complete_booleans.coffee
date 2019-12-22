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

  # This should allow for `/tasks?filter=all` redirects, e.g. from notifications
  # Including others tabs-filtered tables (like properties)
  # TODO: not working as expected. Should:
  # 1. Set the tabs bar (see try below)
  # 2. Ajax the Datatable: table.ajax.url(uri).load( (json) -> ...)
  # (1) TRY:
  # tabEl = document.getElementByID()
  # tabs = M.Tabs.getInstance(tabsEl)
  # tabs.select(targetID)

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
    else
      action = '/un_complete'

    taskId = $(this).siblings('.task_id').text().trim()
    location = '/tasks/' + taskId + action
    $.ajax(url: location).done (response) ->
      M.toast({html: response['status']})
      filter = $('a.active').attr('data-filter')
      table = $('#task_table').DataTable()
      uri = '/tasks.json?filter=' + filter
      table.ajax.url(uri).load( (json) ->
        reInitTooltips()
      )
      true
    true
  true

