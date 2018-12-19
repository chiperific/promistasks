$(document).on 'turbolinks:load', ->
  sideNav = document.querySelectorAll('.sidenav')
  M.Sidenav.init(sideNav)

  fixedActionBtn = document.querySelectorAll('.fixed-action-btn')
  M.FloatingActionButton.init(fixedActionBtn, {
    'hoverEnabled': false,
    'direction': 'top'
    })

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

  datePickers = document.querySelectorAll('.datepicker')
  M.Datepicker.init(datePickers, {
    'format': 'mmm dd, yyyy',
    'showClearBtn': true
    })

  modals = document.querySelectorAll('.modal')
  M.Modal.init(modals, {
    'preventScrolling': true,
    'dismissable': true
    })

  $('select').formSelect()

  tooltips = document.querySelectorAll('.tooltipped')
  M.Tooltip.init(tooltips, {
    'enterDelay': 800
    })

  $('body').on 'click', 'a.prevent_default', ->
    event.preventDefault
    false
