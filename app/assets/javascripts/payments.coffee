$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['payments']) &&
    actionMatches(['create', 'edit', 'new', 'update'])

  unselectCheckboxes = (target, focus) ->
    # focus == 't' || 'f' : as in 'to_' and 'for_'
    if focus == 't'
      scope = 'div#to_checkboxes'
    else
      scope = 'div#for_checkboxes'

    $(scope).find('input[type="checkbox"]').prop("checked", false)

  setMasterField = (value, focus) ->
    if focus == 't'
      target = 'input#payment_paid_to'
    else
      target = 'input#payment_on_behalf_of'
    unless $(target).val() == 'organization'
      $(target).val(value)

  $('span').on 'click', ->
    checker = $(this).siblings('input[type="checkbox"]').prop('checked')
    focus = $(this).siblings('input[type="checkbox"]').attr('id').substring(0,1)
    target = $(this).siblings('input').attr('id')
    targetDiv = target.replace('_opt','')
    unselectCheckboxes(targetDiv, focus)
    if focus == 't'
      value = targetDiv.replace('to_','')
      $('div#to_select_fields').find('div.to_toggle').hide()
    else # focus == 'f'
      value = targetDiv.replace('for_','')
      $('div#for_select_fields').find('div.for_toggle').hide()
    if !checker # checker == false means checkbox is un-checked, being checked
      $('div#' + targetDiv).show()
      setMasterField(value, focus)
    else
      setMasterField('', focus)
      $(this).siblings('input[type="checkbox"]').prop('checked', true)
