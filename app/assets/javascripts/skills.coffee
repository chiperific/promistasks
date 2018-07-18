# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
stripFromOther = (id, target) ->
  current = $(target).val()
  fresh = current.replace(id, '')
  fresh = fresh.replace(',,', ',')
  if fresh[0] == ','
    fresh = fresh.substr(1)
  if fresh[fresh.length - 1] == ','
    fresh = fresh.substr(0, fresh.length - 1)
  $(target).val(fresh)
  true

addElement = (id) ->
  current = $('#add').val()
  if current.length == 0
    $('#add').val(id)
  else
    $('#add').val(current + ',' + id)
  true

removeElement = (id) ->
  current = $('#remove').val()
  if current.length == 0
    $('#remove').val(id)
  else
    $('#remove').val(current + ',' + id)
  true

$(document).on 'turbolinks:load', ->
  $('input:checkbox').on 'change', ->
    divId = $(this).attr('id')
    if $(this).prop('checked')
      addElement(divId)
      stripFromOther(divId, '#remove')
    else
      removeElement(divId)
      stripFromOther(divId, '#add')
    true
