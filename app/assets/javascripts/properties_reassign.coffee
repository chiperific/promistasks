$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['properties']) && actionMatches(['reassign'])

  findParkId = (park_name) ->
    finder = 'span[data-park-name="' + park_name + '"]'
    target = $('div#park_list').find(finder)
    $(target).attr('data-park-id')

  updateView = (response) ->
    prop_target = 'tr#' + response.property_id
    $(prop_target).find('td.park-name').html(response.park_name)
    msg = response.property_name + ' reassigned to ' + response.park_name
    M.toast({html: msg})
    $(prop_target).find('input.select-dropdown').val("")


  updateProperty = (park_id, prop_id) ->
    location = '/properties/' + prop_id + '/reassign_to/?park_id=' + park_id
    $.ajax(url: location).done (response) ->
      if response.status == 'success'
        updateView(response)
      else
        msg = 'Oops, failed to reassign ' + response.property_name + ' to ' + response.park_name
        M.toast({html: msg})
      true

  $('ul.select-dropdown li').on 'click', ->
    row = $(this).parents('tr')
    prop_id = $(row).attr('id')
    park_name = $(row).find('input.select-dropdown').val()
    park_id = findParkId(park_name)
    updateProperty(park_id, prop_id)
