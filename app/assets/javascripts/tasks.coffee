$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['tasks']) &&
  actionMatches(['create', 'edit', 'new'])

  highlightField = (elem, value) ->
    if value != "0" && value != "" && value != 0
      $(elem).addClass('found_match')
    else
      $(elem).removeClass('found_match')

  findUserByName = (elem, targetString) ->
    name = $(elem).prop('value').replace(' ','+')
    target = '/users/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)
      highlightField(elem, response)

  findPropertyByName = (elem, targetString) ->
    name = $(elem).prop('value').replace(' ','+')
    target = '/properties/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)
      highlightField(elem, response)

  highlightField('#property_lkup', $('#task_property_id').val())
  highlightField('#owner_lkup', $('#task_owner_id').val())
  highlightField('#subject_lkup', $('#task_subject_id').val())
  highlightField('#creator_lkup', $('#task_creator_id').val())

  $.ajax(url: '/users/owner_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-owners')
    M.Autocomplete.init(autoComplete, { data: response })

  $.ajax(url: '/users/subject_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-subjects')
    M.Autocomplete.init(autoComplete, { data: response })

  $.ajax(url: '/properties/property_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-properties')
    M.Autocomplete.init(autoComplete, { data: response })

  $('#owner_lkup').on
    'input'      : -> findUserByName(this, '#task_owner_id')
    'change'     : -> findUserByName(this, '#task_owner_id')

  $('#creator_lkup').on
    'input'      : -> findUserByName(this, '#task_creator_id')
    'change'     : -> findUserByName(this, '#task_creator_id')

  $('#subject_lkup').on
    'input'      : -> findUserByName(this, '#task_subject_id')
    'change'     : -> findUserByName(this, '#task_subject_id')

  $('#property_lkup').on
    'input'      : -> findPropertyByName(this, '#task_property_id')
    'change'     : -> findPropertyByName(this, '#task_property_id')
  true

  $('.dropdown-content').on
    'click': ->
      findUserByName('#owner_lkup', '#task_owner_id')
      findUserByName('#creator_lkup', '#task_creator_id')
      findUserByName('#subject_lkup', '#task_subject_id')
      findPropertyByName('#property_lkup', '#task_property_id')


