refreshTasks = (target, checked) ->
  $.ajax(url: target).done (response) ->
    if checked == true
      msg = 'Marked complete!'
    else
      msg = 'Removed completion.'
    M.toast({html: msg})
    true
  true

setActiveTab = (target, scope) ->
  attrSelector = 'ul[name="' + scope + '"]'
  anchors = $(attrSelector).find('a')
  anchors.removeClass('active')
  targetID = 'a#' + scope + '_' + target
  $(targetID).addClass('active')

$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['tasks', 'properties', 'users', 'connections', 'parks']) &&
  actionMatches(['show', 'index', 'tasks'])

  if getParameterByName('filter') != null
    target = document.location.search.replace('?filter=','')
    scope = $('ul.tabs').attr('name')
    setActiveTab(target, scope)

  # Don't initiate this in global
  # because then the JS indicator (non-CSS bottom border)
  # appears on the initial active element
  tab = $('.tabs')
  tabElem = M.Tabs.init(tab)

  $('#task_table_body').on 'click', 'input.complete_bool', ->
    taskId = $(this).siblings('.task_id').text().trim()
    checked = $(this).prop('checked')
    if checked == true
      action = '/complete'
    else
      action = '/un_complete'

    location = '/tasks/' + taskId + action
    $.ajax(url: location).done (response) ->
      filter = $('a.active').attr('id')
      link = '#' + filter
      target = $(link).attr('href')
      refreshTasks(target, checked)
      true
    true
  true

