trackPosition = (event) ->
  idsInOrder = $('.sortable').sortable('toArray')
  positions = 'auto_task[positions]=' + idsInOrder
  console.log(positions)
  # ajax this to /auto_tasks/reposition
  Rails.ajax({
    url: '/auto_tasks/reposition',
    type: 'POST',
    data: new URLSearchParams(positions).toString()
  })

$(document).on 'turbolinks:load', ->
  $('.sortable').sortable({
    axis: 'y',
    handle: '.handle',
    update: (event, ui)-> trackPosition(event),
    classes: {
        "ui-sortable": "highlight",
        "ui-sortable-helper": "highlight"
      }
    })
