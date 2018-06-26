$(document).on 'turbolinks:load', ->
  $('.sidenav').sidenav()
  $('.fixed-action-btn').floatingActionButton()

  dDElems = document.querySelectorAll('.dropdown-trigger')
  M.Dropdown.init(dDElems, {'hover': true, 'coverTrigger': false, 'constrainWidth': false})

  $('a.prevent_default').click ->
    event.preventDefault
    false

