# $(document).on 'turbolinks:load', ->
#   # clear out the modal form on close
#   elem = document.querySelector('#task_modal')
#   M.Modal.init(elem, {
#     'preventScrolling': true,
#     'dismissable': false,
#     'onCloseEnd': ->
#        $('input#auto_task_title').val('')
#        $('textarea#auto_task_notes').val('')
#        $('input#auto_task_days_until_due').val('0')
#        document.getElementById("#auto_task_form").setAttribute('action', '/auto_tasks')
#     })
