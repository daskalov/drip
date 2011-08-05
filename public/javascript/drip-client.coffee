drip = window.drip = (->
  components = {}
  renderedOnce = false

  # Augment jQuery selector with drip properties
  # Represent a single drip component
  component = (sel) ->
    comp = sel.drip = {}
    name = sel.attr 'component'

    # Fetch server-side markup
    sync = (afterSync) ->
      now.driprender name, (mk) ->
        comp.markup = mk
        afterSync() if afterSync?

    # Create a guid on element having `drip` attribute
    attachGuidFromDripAttr = (s) ->
      dripId = s.attr 'drip'
      if dripId?
        guid = "#{name}_#{dripId}"
        s.attr 'guid', guid

    # Transformations on all children of a component
    postProcessComponent = (c) ->
      _.each c.children(), (kid) ->
        kid = $ kid unless kid.attr?
        attachGuidFromDripAttr kid

    # Render markup on page
    draw = ->
      sel.html comp.markup
      postProcessComponent sel

    # Render the component
    render = (fn) ->
      sync ->
        draw()
        fn() if fn?
    components[name] = sel

    sel.sync = sync
    sel.draw = draw
    sel.render = render
    sel


  # Render a single component from a jQuery selector
  renderComponent = (sel, fn) ->
    comp = component sel
    comp.render fn

  # Retrieve all drip components in the DOM
  allPageComponents = ->
    els = _.map $('*'), (e) -> $(e)
    _.filter els, (e) -> isDrip e

  # Render all drip components on the page
  renderAll = (fn) ->
    unless renderedOnce
      renderedOnce = true
      comps = allPageComponents()
      _.last(comps).isLast = true
      _.each comps, (sel) ->
        renderComponent sel, ->
          fn() if fn? and sel.isLast

  # true if a jQuery selector represents a drip object
  isDrip = (sel) -> sel.attr('drip') == 'true'

  # Create an object with form element key-value pairs
  #   name attribute: form value
  formPackage = ->
    form = $('#drip_form')
    formPairs = {}
    _.each form.children(), (c) ->
      c = $(c) unless c.attr?
      nameAttr = c.attr('name')
      formPairs[nameAttr] = c.val() if nameAttr?
    formPairs

  # Very basic event system
  ev = (->
    evs = []
    groups = {}
    execAll = (a) -> _.each a, (f) -> f()
    addTo: (g, f) ->
      group = groups[g] ||= []
      group.push(f)
      evs.push(f)
    add: (f) -> evs.push(f)
    all: -> execAll evs
    allIn: (g) -> execAll groups[g] if groups[g]?
  )()

  # Intial page render call
  # fn executed after all coponents are rendered
  ready: (fn) ->
    now.ready ->
      renderAll fn
  # Re-render a component
  refresh: (name) -> components[name].render()
  # Get a drip component by name
  component: (name) -> components[name]
  formPackage: formPackage
  # Expose entire event system
  events: ev
)()
