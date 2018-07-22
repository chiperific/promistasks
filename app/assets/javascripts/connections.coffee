$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['connections']) &&
    actionMatches(['create', 'edit', 'new', 'update'])

  highlightField = (elem, value) ->
    if value != "0" && value != "" && value != 0
      $(elem).addClass('found_match')
    else
      $(elem).removeClass('found_match')

  findPropertyByName = (elem, targetString) ->
    name = $(elem).prop('value').replace(' ','+')
    target = '/properties/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)
      highlightField(elem, response)

  findUserByName = (elem, targetString) ->
    name = $(elem).prop('value').replace(' ','+')
    target = '/users/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)
      highlightField(elem, response)

  checkRelationship = ->
    if $('#connection_relationship').val() == 'tennant'
      $('.stage_field').show()
    else
      $('.stage_field').hide()

  checkRelationship()
  highlightField('#property_lkup', $('#connection_property_id').val())
  highlightField('#user_lkup', $('#connection_user_id').val())


  $.ajax(url: '/properties/property_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-properties')
    M.Autocomplete.init(autoComplete, {
      data: response
    })

  $.ajax(url: '/users/subject_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-users')
    M.Autocomplete.init(autoComplete, {
      data: response
    })

  $('#property_lkup').on
    'input'      : -> findPropertyByName(this, '#connection_property_id')
    'change'     : -> findPropertyByName(this, '#connection_property_id')
    'blur'       : -> findPropertyByName(this, '#connection_property_id')
    'focusout'   : -> findPropertyByName(this, '#connection_property_id')
    'mouseleave' : -> findPropertyByName(this, '#connection_property_id')

  $('#user_lkup').on
    'input'      : -> findUserByName(this, '#connection_user_id')
    'change'     : -> findUserByName(this, '#connection_user_id')
    'blur'       : -> findUserByName(this, '#connection_user_id')
    'focusout'   : -> findUserByName(this, '#connection_user_id')
    'mouseleave' : -> findUserByName(this, '#connection_user_id')

  $('#select_relationship').on 'change', 'select', ->
    checkRelationship()
  true
