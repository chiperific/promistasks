$(document).on 'turbolinks:load', ->
  $('#slide-out').sidenav()

  $('.fixed-action-btn').floatingActionButton()

  elems = document.querySelectorAll('.dropdown-trigger')
  M.Dropdown.init(elems, {'hover': true, 'coverTrigger': false, 'constrainWidth': false})

  $('a.prevent_default').click ->
    event.preventDefault
    false

