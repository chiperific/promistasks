# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on 'turbolinks:load', ->
  findUserByName = (elem, targetString) ->
    name = $(elem).prop('value').replace(' ','+')
    target = '/users/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)

  findPropertyByName = (elem, targetString) ->
    name = $(elem).prop('value').replace(' ','+')
    target = '/properties/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)

  $.ajax(url: '/users/owner_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-owners')
    M.Autocomplete.init(autoComplete, {
      data: response
    })

  $.ajax(url: '/users/subject_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-subjects')
    M.Autocomplete.init(autoComplete, {
      data: response
    })

  $.ajax(url: '/properties/property_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-properties')
    M.Autocomplete.init(autoComplete, {
      data: response
    })

  $('#owner_lkup').on
    'input'      : -> findUserByName(this, '#task_owner_id')
    'change'     : -> findUserByName(this, '#task_owner_id')
    'blur'       : -> findUserByName(this, '#task_owner_id')
    'focusout'   : -> findUserByName(this, '#task_owner_id')
    'mouseleave' : -> findUserByName(this, '#task_owner_id')

  $('#creator_lkup').on
    'input'      : -> findUserByName(this, '#task_creator_id')
    'change'     : -> findUserByName(this, '#task_creator_id')
    'blur'       : -> findUserByName(this, '#task_creator_id')
    'focusout'   : -> findUserByName(this, '#task_creator_id')
    'mouseleave' : -> findUserByName(this, '#task_creator_id')

  $('#subject_lkup').on
    'input'      : -> findUserByName(this, '#task_subject_id')
    'change'     : -> findUserByName(this, '#task_subject_id')
    'blur'       : -> findUserByName(this, '#task_subject_id')
    'focusout'   : -> findUserByName(this, '#task_subject_id')
    'mouseleave' : -> findUserByName(this, '#task_subject_id')

  $('#property_lkup').on
    'input'      : -> findPropertyByName(this, '#task_property_id')
    'change'     : -> findPropertyByName(this, '#task_property_id')
    'blur'       : -> findPropertyByName(this, '#task_property_id')
    'focusout'   : -> findPropertyByName(this, '#task_property_id')
    'mouseleave' : -> findPropertyByName(this, '#task_property_id')
  true


