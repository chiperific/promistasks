$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['users'])

  checkForContractor = () ->
    value = $('li.selected span').html()
    if value == 'Contractor'
      $('#rate_div').addClass('scale-in')
      $('#rate_div').removeClass('scale-out')
    else
      $('#rate_div').removeClass('scale-in')
      $('#rate_div').addClass('scale-out')


  $('#user_register_as').on
    'change': -> checkForContractor()
    'click' : -> checkForContractor()
    true

  $('.dropdown-content').on
    'click': -> checkForContractor()
    true
