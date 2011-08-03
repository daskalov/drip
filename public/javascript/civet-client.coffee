civet = window.civet = (->
  components = {}

  # Augment jQuery selector with civet properties
  # Represent a single civet component
  component = (sel) ->
    comp = sel.civet = {}
    name = sel.attr('component')

    # Fetch server-side markup
    sync = (afterSync) ->
      now.civetrender name, (mk) ->
        comp.markup = mk
        afterSync() if afterSync?

    # Render markup on page
    draw = -> sel.html comp.markup

    # Render the component
    render = (fn) ->
      sync ->
        draw()
        fn() if fn?
    components[name] = sel

    # exposed interface
    sel.sync = sync
    sel.draw = draw
    sel.render = render
    sel


  # Render a single component from a jQuery selector
  renderComponent = (sel, fn) ->
    comp = component(sel)
    comp.render fn

  # Retrieve all civet components in the DOM
  allPageComponents = ->
    els = _.map($('*'), (e) -> $(e))
    _.filter els, (e) -> isCivet e

  # Render all civet components on the page
  renderAll = (fn) ->
    comps = allPageComponents()
    _.last(comps).isLast = true
    _.each comps, (sel) ->
      renderComponent sel, ->
        fn() if fn? and sel.isLast

  # true if a jQuery selector represents a civet object
  isCivet = (sel) -> sel.attr('civet') == 'true'

  # exposed interface
  {
    # Intial page render call
    # fn executed after all coponents are rendered
    ready: (fn) ->
      now.ready ->
        renderAll fn
    # Re-render a component
    # Re-render all components with no arguments
    refresh: (name) ->
      if name? components[name].render()
      else     renderAll()
    # Get a civet component by name
    component: (name) ->
      components[name]
  }
)()
