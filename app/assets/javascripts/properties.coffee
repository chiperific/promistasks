$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['properties']) && actionMatches(['list'])

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
