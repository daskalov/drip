civet =
  renderAll: ->
    now.render 'walls:list', (ret) ->
      $('#stuff').append(ret)

now.ready -> civet.renderAll
