civet = window.civet = {}

civet.renderAll = (fn) ->
  els = _.map($('*'), (e) -> $(e))
  comps = _.filter els, (e) -> civet.isCivet e
  i = 0 # hacky indexing
  for sel in comps
    compName = sel.attr('component')
    now.civetrender compName, (markup) ->
      sel.append(markup)
      fn() if fn? and ++i == comps.length

civet.isCivet = (sel) -> sel.attr('civet') == 'true'

civet.ready = (fn) ->
  now.ready ->
    civet.renderAll fn
