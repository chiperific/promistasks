$(document).on 'turbolinks:load', ->
  sideNav = document.querySelectorAll('.sidenav')
  M.Sidenav.init(sideNav)

  fixedActionBtn = document.querySelectorAll('.fixed-action-btn')
  M.FloatingActionButton.init(fixedActionBtn)

  dDHoverElems = document.querySelectorAll('.dropdown-trigger-hover')
  M.Dropdown.init(dDHoverElems, {
    'hover': true,
    'coverTrigger': false,
    'constrainWidth': false,
    'outDuration': 450
    })

  dDElems = document.querySelectorAll('.dropdown-trigger')
  M.Dropdown.init(dDElems, {
    'coverTrigger': false,
    'constrainWidth': false,
    'outDuration': 450
    })

  $('body').on 'click', 'a.prevent_default', ->
    event.preventDefault
    false
