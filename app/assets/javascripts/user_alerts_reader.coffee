handleAlertJson = (user_id) ->
  alertUrl = window.location.origin + '/users/' + user_id + '/alerts'
  $.ajax(url: alertUrl).done (response) ->
    if response['show_alert'] == true
      $('#alert_btn').show()
      $('#alert_btn').addClass(response['alert_color'])
      if response['pulse_alert'] == true
        $('#alert_btn').addClass('pulse')
      if response['tasks_past_due']['count'] != 0
        $('#tasks_past_due').show()
        $('#tasks_past_due').find('span').html(
          response['tasks_past_due']['msg']
        )
      if response['properties_over_budget']['count'] != 0
        $('#properties_over_budget').show()
        $('#properties_over_budget').find('span').html(
          response['properties_over_budget']['msg']
        )
      if response['properties_nearing_budget']['count'] != 0
        $('#properties_nearing_budget').show()
        $('#properties_nearing_budget').find('span').html(
          response['properties_nearing_budget']['msg']
        )
      if response['tasks_due_7']['count'] != 0
        $('#tasks_due_7').show()
        $('#tasks_due_7').find('span').html(response['tasks_due_7']['msg'])
      if response['tasks_missing_info']['count'] != 0
        $('#tasks_missing_info').show()
        $('#tasks_missing_info').find('span').html(
          response['tasks_missing_info']['msg']
        )
      if response['tasks_due_14']['count'] != 0
        $('#tasks_due_14').show()
        $('#tasks_due_14').find('span').html(response['tasks_due_14']['msg'])
      if response['tasks_new']['count'] != 0
        $('#tasks_new').show()
        $('#tasks_new').find('span').html(response['tasks_new']['msg'])
      true
    true
  true

$(document).on 'turbolinks:load', ->
  $.get '/current_user_id', (response) ->
    if response['id'] != '0'
      handleAlertJson(response['id'])

