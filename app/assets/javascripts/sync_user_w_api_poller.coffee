reset = (msg, cred_err) ->
  clear_jobs_uri = window.location.origin + "/users/clear_completed_jobs"
  clear_jobs_uri += '?cred_err=true' if cred_err == true
  M.toast(html: msg) if msg
  window.location.replace(clear_jobs_uri)
  $('#refresh_button').removeClass('prevent_default')

pollDelayedJobs = (jobId) ->
  $.ajax(
    url: "/delayed/jobs/" + jobId,
    statusCode:
      404: ->
        reset()
  ).done (response) ->
    $('#sync_bar_indeterminate').hide()
    if response.length == 0
      reset()
    else if response.error_message != null
      msg = 'Uh oh, an error occured: <br /> ' + response.error_message
      reset(msg)
    else if response.message == 'Credential error!'
      reset(response.message, true)
    else if response.status == 'completed' || response.message == 'Done!'
      reset('Done!')
    else # job is ongoing, repeat
      $('#sync_bar_determinate').show()
      $('#status').html(response.message)
      progress = parseInt(
        (response.progress_current / response.progress_max) * 100
      ).toString() + "%"
      $(".determinate").width(progress)
      repeater(jobId)
      true

repeater = (jobId) ->
  setTimeout(pollDelayedJobs, 500, jobId)
  true

targetHasParameter = (url) ->
  regex = /\?/
  result = regex.exec(url)
  !!result

addSyncToAllLinks = (link) ->
  target = $(link).attr('href')
  if target != '#' && getParameterByName('syncing', target) != 'true'
    if targetHasParameter(target) == true
      newTarget = target + '&syncing=true'
    else
      newTarget = target + '?syncing=true'
    $(link).attr('href', newTarget)


$(document).on 'turbolinks:load', ->
  if getParameterByName('syncing') == 'true'
    $('#sync_box').show()
    $('#sync_bar_indeterminate').show()
    $('#refresh_button').addClass('prevent_default')
    jobId = $('#job_id').attr('value')
    if jobId == "0"
      uri = window.location.origin + window.location.pathname
      window.location.replace(uri)
    else
      allLinks = document.querySelectorAll('a')
      allLinks.forEach((currentLink)->
        addSyncToAllLinks(currentLink)
      )
      repeater(jobId)
    true
