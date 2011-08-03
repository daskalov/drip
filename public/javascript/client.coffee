civet.ready ->
  $('#wall_add_button').click ->
    v = $('#wall_add_input').val()
    now.makeWall(v, '', -> civet.component('walls:list').render())
