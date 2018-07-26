handleAlertJson = (userId) ->
  alertUrl = window.location.origin + '/users/' + userId + '/alerts'
  $.ajax(url: alertUrl).done (response) ->
    if response['show_alert'] == true
      $('#alert_btn').show()
      $('#alert_btn').addClass(response['alert_color'])
      if response['pulse_alert'] == true
        $('#alert_btn').addClass('pulse')
      else
        $('#alert_btn').removeClass('pulse')
      if response['tasks_past_due']['count'] != 0
        $('#tasks_past_due').show()
        $('#tasks_past_due').find('span').html(
          response['tasks_past_due']['msg']
        )
      else
        $('#tasks_past_due').hide()
        $('#tasks_past_due').find('span').html('')
      if response['properties_over_budget']['count'] != 0
        $('#properties_over_budget').show()
        $('#properties_over_budget').find('span').html(
          response['properties_over_budget']['msg']
        )
      else
        $('#properties_over_budget').hide()
        $('#properties_over_budget').find('span').html('')
      if response['properties_nearing_budget']['count'] != 0
        $('#properties_nearing_budget').show()
        $('#properties_nearing_budget').find('span').html(
          response['properties_nearing_budget']['msg']
        )
      else
        $('#properties_nearing_budget').hide()
        $('#properties_nearing_budget').find('span').html('')
      if response['tasks_due_7']['count'] != 0
        $('#tasks_due_7').show()
        $('#tasks_due_7').find('span').html(response['tasks_due_7']['msg'])
      else
        $('#tasks_due_7').hide()
        $('#tasks_due_7').find('span').html('')
      if response['tasks_missing_info']['count'] != 0
        $('#tasks_missing_info').show()
        $('#tasks_missing_info').find('span').html(
          response['tasks_missing_info']['msg']
        )
      else
        $('#tasks_missing_info').hide()
        $('#tasks_missing_info').find('span').html('')
      if response['tasks_due_14']['count'] != 0
        $('#tasks_due_14').show()
        $('#tasks_due_14').find('span').html(response['tasks_due_14']['msg'])
      else
        $('#tasks_due_14').hide()
        $('#tasks_due_14').find('span').html('')
      if response['tasks_new']['count'] != 0
        $('#tasks_new').show()
        $('#tasks_new').find('span').html(response['tasks_new']['msg'])
      else
        $('#tasks_new').hide()
        $('#tasks_new').find('span').html('')
      true
    else # response['show_alert'] != true
      $('#alert_btn').hide()
      $('#alert_btn').removeClass(response['alert_color'])
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
