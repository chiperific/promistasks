tabRowVisibility = ->
  chooser = $('#tab_switch').prop('checked')

  if chooser == false #Tasks
    $('#properties_status').hide()
    $('#properties_tasks').show()

    taskTabEl = document.getElementById('properties_tasks')
    taskTab = M.Tabs.getInstance(taskTabEl)
    taskTab.updateTabIndicator()
  else
    $('#properties_tasks').hide()
    $('#properties_status').show()

    statusTabEl = $('#properties_status')
    statusTab = M.Tabs.getInstance(statusTabEl)
    statusTab.updateTabIndicator()
  true

$(document).on 'turbolinks:load', ->
  return unless (
    controllerMatches(['properties']) && actionMatches(['list'])
  ) || (
    controllerMatches(['parks']) && actionMatches(['show'])
  )

  tabRowVisibility()

  $('#tab_switch').on 'change', ->
    tabRowVisibility()
    true

  # properties#list && parks#show AJAX property#stage updates
  # have to bubble up from document after AJAXing tabs
  $(document).on 'change', 'select.stage-select', ->
    id = $(this).attr('data-finder')
    stage = $(this).val()
    uri = '/properties/' + id + '/update_stage?stage=' + stage
    $.ajax(url: uri).done (response) ->
      M.toast({html: response})
  true
