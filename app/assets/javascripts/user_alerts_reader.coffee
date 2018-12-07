
  # alert name

handleAlertJson = (userId) ->
  alertUrl = window.location.origin + '/users/' + userId + '/alerts'
  $.ajax(url: alertUrl).done (response) ->
    if response.setup.show_alert == true
      $('#alert_btn').show()
      $('#alert_btn').addClass(response.setup.alert_color)
      if response.setup.pulse_alert == true
        $('#alert_btn').addClass('pulse')
      else
        $('#alert_btn').removeClass('pulse')
      # iterate over the elements of response.alerts
      handleListItems = for type, details of response.alerts
        if details.count != 0
          $('#' + type).show()
          $('#' + type).find('span').html(details.msg)
        else
          $('#' + type).hide()
          $('#' + type).find('span').html('')
    else # response['show_alert'] != true
      $('#alert_btn').hide()
      $('#alert_btn').removeClass(response.setup.alert_color)
    true
  true

getCurrentUser = ->
  $('body').data('user')

$(document).on 'turbolinks:load', ->
  userId = getCurrentUser()
  unless userId == 0
    handleAlertJson(userId)

# update the _alerts partial after ajax on the following:
# Task#index && Property#list through a.pagination_btn
# _task_table partial through input.complete_bool
$(document).ready ->
  $('input.complete_bool').on "ajax:success", (event) ->
    userId = getCurrentUser()
    unless userId == 0
      handleAlertJson(userId)
