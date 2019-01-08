styleButton = (button) ->
  $(button).removeClass('dt-button')
  $(button).addClass('waves-effect waves-light btn green darken-2')


$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['properties']) &&
    actionMatches(['reports'])

  div = $('div.dt-buttons')
  buttons = $(div).children('button')
  styleButton(button) for button in buttons

