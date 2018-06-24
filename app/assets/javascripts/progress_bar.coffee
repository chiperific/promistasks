pollDelayedJobs = (jobId) ->
  $.ajax(url: "/delayed/jobs/" + jobId).done (response) ->
    $('#sync_bar_indeterminate').hide()
    $('#sync_bar_determinate').show()
    if response.length == 0
      uri = window.location.origin + window.location.pathname
      window.location.replace(uri)
      M.toast({html: 'Nothing left. There\'s nothing left!!' })
      $('#sync_bar_determinate').hide()
    else if response.error_message != null
      toastMsg = 'Uh oh, an error occured: <br /> ' + response.error_message
      M.toast({html: toastMsg})
      $('#sync_bar_determinate').hide()
    else
      M.toast({html: response.message, displayLength: 1000 })
      repeater(jobId)
      true

repeater = (jobId) ->
  setTimeout(pollDelayedJobs, 5000, jobId)
  true

$(document).on 'turbolinks:load', ->
  if getParameterByName('syncing') == "true"
    jobId = $('#job_id').attr("value")
    pollDelayedJobs(jobId)
    true
