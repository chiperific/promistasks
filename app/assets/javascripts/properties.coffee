$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['properties', 'parks']) && actionMatches(['list', 'show'])

  tabRowVisibility = ->
    chooser = $('#tab_switch').prop('checked')
    if chooser == false #Tasks
      $('#properties_status').hide()
      $('#properties_tasks').show()
      taskTab.updateTabIndicator()
    else
      $('#properties_tasks').hide()
      $('#properties_status').show()
      statusTab.updateTabIndicator()
    true

  tabs = $('.tabs')
  M.Tabs.init(tabs)

  taskTabEl = $('#properties_tasks')
  taskTab = M.Tabs.getInstance(taskTabEl)

  statusTabEl = $('#properties_status')
  statusTab = M.Tabs.getInstance(statusTabEl)

  tabRowVisibility()

  $('#tab_switch').on 'change', ->
    tabRowVisibility()
    true

  # properties#list AJAX stage updates
  $('.stage-select').on 'change', ->
    id = $(this).attr('data-finder')
    stage = $(this).val()
    uri = '/properties/' + id + '/update_stage?stage=' + stage
    $.ajax(url: uri).done (response) ->
      M.toast({html: response})
