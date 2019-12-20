highlightField = (elem, value) ->
  if value != "0" && value != "" && value != 0
    $(elem).addClass('found_match')
  else
    $(elem).removeClass('found_match')

findUserByName = (elem, targetString) ->
  if $(elem).length
    name = $(elem).prop('value').replace(' ','+')
    target = '/users/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)
      highlightField(elem, response)

findPropertyByName = (elem, targetString) ->
  if $(elem).length
    name = $(elem).prop('value').replace(' ','+')
    target = '/properties/find_id_by_name/?name=' + name
    $.ajax(url: target).done (response) ->
      $(targetString).val(response)
      highlightField(elem, response)

$(document).on 'turbolinks:load', ->
  return unless controllerMatches(['tasks']) &&
  actionMatches(['create', 'edit', 'new', 'index'])

  # form field lookups and dropdowns
  highlightField('#property_lkup', $('#task_property_id').val())
  highlightField('#owner_lkup', $('#task_owner_id').val())
  highlightField('#subject_lkup', $('#task_subject_id').val())
  highlightField('#creator_lkup', $('#task_creator_id').val())

  $.ajax(url: '/users/owner_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-owners')
    M.Autocomplete.init(autoComplete, { data: response })

  $.ajax(url: '/users/subject_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-subjects')
    M.Autocomplete.init(autoComplete, { data: response })

  $.ajax(url: '/properties/property_enum').done (response) ->
    autoComplete = document.querySelectorAll('input.autocomplete-properties')
    M.Autocomplete.init(autoComplete, { data: response })

  $('#owner_lkup').on
    'input'      : -> findUserByName(this, '#task_owner_id')
    'change'     : -> findUserByName(this, '#task_owner_id')

  $('#creator_lkup').on
    'input'      : -> findUserByName(this, '#task_creator_id')
    'change'     : -> findUserByName(this, '#task_creator_id')

  $('#subject_lkup').on
    'input'      : -> findUserByName(this, '#task_subject_id')
    'change'     : -> findUserByName(this, '#task_subject_id')

  $('#property_lkup').on
    'input'      : -> findPropertyByName(this, '#task_property_id')
    'change'     : -> findPropertyByName(this, '#task_property_id')
  true

  $('.dropdown-content').on
    'click': ->
      findUserByName('#owner_lkup', '#task_owner_id')
      findUserByName('#creator_lkup', '#task_creator_id')
      findUserByName('#subject_lkup', '#task_subject_id')
      findPropertyByName('#property_lkup', '#task_property_id')
      true

  $('input[type="submit"]').on 'click', (e)->
    e.preventDefault()
    findUserByName('#owner_lkup', '#task_owner_id')
    findUserByName('#creator_lkup', '#task_creator_id')
    findUserByName('#subject_lkup', '#task_subject_id')
    findPropertyByName('#property_lkup', '#task_property_id')
    $('form').submit()
    true

  # dataTables ajax links
  $("table#task_table").DataTable( {
    ajax: {
      url: '/tasks.json',
      dataSrc: ''
    },
    columns: [
      { data: 'notice' },
      { data: 'priority' },
      { data: 'title' },
      { data: 'assigned_to' },
      { data: 'property' },
      { data: 'due' },
      { data: 'completion' },
      { data: 'show' },
      { data: 'edit' }
    ],
    responsive: true,
    order: [1, 'desc'],
    columnDefs: [ {
      "searchable": false,
      "orderable": false,
      "targets": [0, -1, -2, -3],
    },
    {
      className: "center-align",
      targets: [1, 5, 6, 7, 8]
    }
    ],
    dom: "<'#dttbl.row'tr>",
    initComplete: (settings, json) ->
      reInitTooltips()
  } )

  # Task#index ajaxing on tab clicks
  $('a.dttb-ajax-link').on 'click', ->
    filter = $(this).attr('data-filter')
    table = $('#task_table').DataTable()
    dttbAjaxTrigger(filter, table)

