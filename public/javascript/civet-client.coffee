civet = window.civet = (->
  components = {}

  # Render a single component from a jQuery selector
  renderComponent = (sel, fn) ->
    compName = sel.attr('component')
    now.civetrender compName, (markup) ->
      sel.html(markup)
      fn()

  # Render all civet components on the page
  renderAll = (fn) ->
    els = _.map($('*'), (e) -> $(e))
    comps = _.filter els, (e) -> isCivet e
    i = 0 # hacky indexing
    _.each comps, (sel) ->
      renderComponent sel, ->
        fn() if fn? and ++i == comps.length

  # true if a jQuery selector represents a civet object
  isCivet = (sel) -> sel.attr('civet') == 'true'

  # PUBLIC API
  {
    ready: (fn) ->
      now.ready ->
        renderAll fn

    refresh: renderAll
  }
)()
