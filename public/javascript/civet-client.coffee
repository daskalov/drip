civet = window.civet = {}

civet.renderAll = ->
  _.each $('*'), (e) ->
    sel = $(e)
    if civet.isCivet sel
      compName = sel.attr('component')
      now.render compName, (ret) ->
        sel.append(ret)

civet.isCivet = (sel) -> sel.attr('civet') == 'true'

civet.ready = (fn) ->
  now.ready ->
    fn() if fn?
    civet.renderAll()
