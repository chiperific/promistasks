pollDelayedJobs = (jobId) ->
  $.ajax(url: "/delayed/jobs/" + jobId).done (response) ->
    if response.error_message != undefined
      M.toast({html: response.error_message })
      $('#sync_bar_indeterminate').removeClass('show')
      $('#sync_bar_indeterminate').addClass('hide')
    else
      $('#sync_bar_indeterminate').removeClass('show')
      $('#sync_bar_indeterminate').addClass('hide')
      $('#sync_bar_determinate').removeClass('hide')
      $('#sync_bar_determinate').addClass('show')
      M.toast({html: response.message })

$(document).on 'turbolinks:load', ->
  if getParameterByName('syncing') == "true"
    jobId = $('#job_id').attr("value")
    pollDelayedJobs(jobId)
