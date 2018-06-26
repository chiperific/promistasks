jQuery ->
  $('#new_user input.form-check-input').change ->
    target = $(this).attr('value')
    inputTarget = 'input[name*="user[' + target.toLowerCase() + ']"]'
    $('#hidden_booleans').find('input').val('0')
    $(inputTarget).val('1')

$(document).on 'turbolinks:load', ->
  $('select').formSelect()
