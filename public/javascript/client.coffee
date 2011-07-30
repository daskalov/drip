civet =
  applyToAllElements: (fn) ->
    toAll = (els) ->
      if (els.length > 0)
        _.each els, (e) -> fn e
        toAll els.children()
    toAll $('body').children()
  renderAll: ->
    civet.applyToAllElements (e) ->
      sel = $(e)
      if civet.isCivet sel
        compName = sel.attr('component')
        now.render compName, (ret) ->
          sel.append(ret)
  isCivet: (sel) -> sel.attr('civet') == 'true'
  ready: (fn) ->
    now.ready ->
      fn() if fn?
      civet.renderAll()

civet.ready()
