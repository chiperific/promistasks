$(document).on 'turbolinks:load', ->
  $('a.paginate_btn').click ->
    $('ul#task_pagination').find('li').removeClass('active')
    $('ul#task_pagination').find('li').removeClass('purple')
    $(this).parent('li').addClass('active')
    $(this).parent('li').addClass('purple')

  refreshTasks = (target, checked) ->
    $.ajax(url: target).done (response) ->
      if checked == true
        msg = 'Marked complete!'
      else
        msg = 'Removed completion.'
      M.toast({html: msg})
      true
    true


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

