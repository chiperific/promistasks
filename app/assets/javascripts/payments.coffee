$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['payments']) &&
    actionMatches(['create', 'edit', 'new', 'update'])

  uri = window.location.href

  defaultShowFields = (target, uri, focus) ->
    # focus == 't' || 'f' : as in 'to_' and 'for_'
    if focus == 't'
      finder = 'div#to_'
    else
      finder = 'div#for_'

    if getParameterByName(target, uri) != null
      if target == 'pay_client' || target == 'for_client'
        target = 'client'
      $(finder + target).show()

  toLoop = ['utility', 'park', 'contractor', 'pay_client']
  defaultShowFields target, uri, 't' for target in toLoop

  forLoop = ['for_client', 'property']
  defaultShowFields target, uri, 'f' for target in forLoop

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

  checkForAssociated = () ->
    paid = $('input#payment_paid')
    due = $('input#payment_due')

    if paid.val().length == 0
      $('div#recurrence_no_paid').show()
      paid.addClass('field_with_errors')
    if due.val().length == 0
      $('div#recurrence_no_due').show()
      due.addClass('field_with_errors')

  resetAssociatedErrors = (context) ->
    if $('input#payment_recurring').prop('checked') == true
      if context.value.length > 0
        $(context).removeClass('field_with_errors')
        target = $(context).attr("id").substring($(context).attr("id").indexOf("_"), $(context).attr("id").length)
        div = 'div#recurrence_no' + target
        $(div).hide()
      else
        checkForAssociated()



  $('span.hidden-field-setter').on 'click', ->
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

  $('span.recurrence-setter').on 'click', ->
    checker = $(this).siblings('input[type="checkbox"]').prop('checked')
    if !checker
      $('div#recurrence_div').show()
      checkForAssociated()
    else
      $('div#recurrence_div').hide()
      $('select#payment_recurrence').val('')
      $('#recurrence_div').find('input').val('')

  $('input#payment_paid').on 'change', ->
    resetAssociatedErrors(this)

  $('input#payment_due').on 'change', ->
    resetAssociatedErrors(this)