# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  $('#contractor_check').change ->
    if $(this).children('input')[0].checked
      $('#rate_div').removeClass('scale-out')
      $('#rate_div').addClass('scale-in')
    else
      $('#rate_div').removeClass('scale-in')
      $('#rate_div').addClass('scale-out')
