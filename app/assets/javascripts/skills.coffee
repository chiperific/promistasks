stripFromOther = (id, target) ->
  val = $(target).val()
  if val.length > 0
    ary = JSON.parse(val)
  else
    ary = []
  index = ary.indexOf(id)
  if index > -1
    ary.splice(index, 1)
  $(target).val(JSON.stringify(ary))
  true

addElement = (id) ->
  val = $('#add').val()
  if val.length > 0
    ary = JSON.parse(val)
  else
    ary = []
  ary.push(id)
  $('#add').val(JSON.stringify(ary))
  true

removeElement = (id) ->
  val = $('#remove').val()
  if val.length > 0
    ary = JSON.parse(val)
  else
    ary = []
  ary.push(id)
  $('#remove').val(JSON.stringify(ary))
  true

# Skill#users, Skill#tasks, User#skills, Task#skills
$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['skills', 'users', 'tasks']) &&
    actionMatches(['users', 'tasks', 'skills'])

  $('input:checkbox.skill-lever').on 'change', ->
    divId = $(this).attr('id')
    if $(this).prop('checked')
      addElement(divId)
      stripFromOther(divId, '#remove')
    else
      removeElement(divId)
      stripFromOther(divId, '#add')
    true
