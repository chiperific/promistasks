$(document).on 'turbolinks:before-visit turbolinks:before-cache', ->
  $('#slide-out').sidenav()

$(document).on 'ready turbolinks:load', ->
  $('#slide-out').sidenav()
