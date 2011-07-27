multiplexer = (comp, fam) ->
  now.render comp, fam, (x) -> alert x

$(document).ready ->
  $('#render_button').click ->
    now.render 'walls:list', (ret) -> $('#stuff').append(ret)
