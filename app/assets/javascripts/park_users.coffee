$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['park_users']) &&
    actionMatches(['create', 'edit', 'new', 'update', 'destroy'])

  highlightField = (elem, value) ->
    if value != "0" && value != "" && value != 0
      $(elem).addClass('found_match')
    else
      $(elem).removeClass('found_match')

  findParkByName = (elem, targetString) ->
    name = $(elem).prop('value').replace(' ','+')
    target = '/parks/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)
      highlightField(elem, response)

  findUserByName = (elem, targetString) ->
    name = $(elem).prop('value').replace(' ','+')
    target = '/users/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)
      highlightField(elem, response)

  highlightField('#park_lkup', $('#park_user_park_id').val())
  highlightField('#user_lkup', $('#park_user_user_id').val())

  $.ajax(url: '/parks/park_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-parks')
    M.Autocomplete.init(autoComplete, {
      data: response
    })

  $.ajax(url: '/users/subject_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-users')
    M.Autocomplete.init(autoComplete, {
      data: response
    })

  $('#park_lkup').on
    'input'      : -> findParkByName(this, '#park_user_park_id')
    'change'     : -> findParkByName(this, '#park_user_park_id')

  $('#user_lkup').on
    'input'      : -> findUserByName(this, '#park_user_user_id')
    'change'     : -> findUserByName(this, '#park_user_user_id')

  $('.dropdown-content').on
    'click': ->
      findParkByName($('#park_lkup', '#park_user_park_id'))
      findUserByName($('#user_lkup', '#park_user_user_id'))
      true

  $('input[name="commit"]').on 'click', (e)->
    e.preventDefault()
    findParkByName($('#park_lkup', '#park_user_park_id'))
    findUserByName($('#user_lkup', '#park_user_user_id'))
    $('form').submit()
    true
