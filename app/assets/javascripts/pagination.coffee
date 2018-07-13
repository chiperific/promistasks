refreshTasks = (target, checked) ->
  $.ajax(url: target).done (response) ->
    if checked == true
      msg = 'Marked complete!'
    else
      msg = 'Removed completion.'
    M.toast({html: msg})
    true
  true

setActivePagination = (target, scope) ->
  attrSelector = 'ul[name="' + scope + '"]'
  lis = $(attrSelector).find('li')
  lis.removeClass('active')
  lis.removeClass('purple')
  targetID = 'a#' + scope + '_' + target
  thisLi = $(targetID).parent('li')
  thisLi.addClass('active')
  thisLi.addClass('purple')



$(document).on 'turbolinks:load', ->
  if getParameterByName('filter') != null
    target = document.location.search.replace('?filter=','')
    scope = $('ul.pagination').attr('name')
    setActivePagination(target, scope)

# TASK: Property#show and Task#index
# PROPERTY: Property#list
  $('a.paginate_btn').click ->
    scope = $('ul.pagination').attr('name')
    scopePrecursor = scope + '_'
    target = $(this).attr('id').replace(scopePrecursor, '')
    setActivePagination(target, scope)

  $('#task_table_body').on 'click', 'input.complete_bool', ->
    taskId = $(this).siblings('.task_id').text().trim()
    checked = $(this).prop('checked')
    if checked == true
      action = '/complete'
    else
      action = '/un_complete'

    location = '/tasks/' + taskId + action
    $.ajax(url: location).done (response) ->
      filter = $('li.active').children('a.paginate_btn').attr('id')
      link = '#' + filter
      target = $(link).attr('href')
      refreshTasks(target, checked)
      true
    true
  true

