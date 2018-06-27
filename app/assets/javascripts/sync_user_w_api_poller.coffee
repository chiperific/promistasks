pollDelayedJobs = (jobId) ->
  $.ajax(url: "/delayed/jobs/" + jobId).done (response) ->
    $('#sync_bar_indeterminate').hide()
    if response.length == 0
      uri = window.location.origin + window.location.pathname
      window.location.replace(uri)
    else if response.error_message != null
      toastMsg = 'Uh oh, an error occured: <br /> ' + response.error_message
      M.toast({html: toastMsg})
    else if response.status == 'completed'
      clearTheUri
      M.toast({html: 'Done!'})
    else
      $('#sync_bar_determinate').show()
      $('#status').html(response.message)
      progress = parseInt((response.progress_current / response.progress_max) * 100).toString() + "%"
      $(".determinate").width(progress)
      repeater(jobId)
      true

repeater = (jobId) ->
  setTimeout(pollDelayedJobs, 1000, jobId)
  true

clearTheUri = ->
  uri = window.location.origin + window.location.pathname
  window.location.replace(uri)

$(document).on 'turbolinks:load', ->
  if getParameterByName('syncing') == "true"
    $('#sync_bar_indeterminate').show()
    jobId = $('#job_id').attr("value")
    if jobId == "0"
      clearTheUri
    else
      repeater(jobId)
    true
