$ ->
  $('a.paginate_btn').click ->
    $('ul#task_pagination').find('li').removeClass('active')
    $('ul#task_pagination').find('li').removeClass('purple')
    $(this).parent('li').addClass('active')
    $(this).parent('li').addClass('purple')
