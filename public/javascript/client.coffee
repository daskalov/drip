drip.ready ->
  $('#wall_add_button').click ->
    v = $('#wall_add_input').val()
    now.makeWall(v, '', -> drip.component('walls:list').render())
