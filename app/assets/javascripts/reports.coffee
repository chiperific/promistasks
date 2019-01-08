$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['properties']) &&
    actionMatches(['reports'])

    # clicking on Show toggel:
    $('#scope_switch').on 'change', ->
      if $(this).prop('checked')
        target = window.location.origin + window.location.pathname + '?include_archived=true'
      else
        target = window.location.origin + window.location.pathname

      window.location.replace(target)
