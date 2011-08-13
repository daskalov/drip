drip = window.drip = (->
  components = {}
  renderedOnce = false

  dripId =
    GUID_SEPERATOR: '___'
    dripToGuid: (cname, dripId) ->
      "#{cname}#{@GUID_SEPERATOR}#{dripId}"
    guidToDrip: (gu) ->
      return undefined unless gu?
      parts = gu.split @GUID_SEPERATOR
      name: parts[0]
      drip: parts[1]

  # Augment jQuery selector with drip properties
  # Represents a single drip component
  component = (sel) ->
    comp = sel.drip = {}
    name = sel.attr 'component'

    # Retrieve an element from the component by drip id
    byDrip = (dId) ->
      els = _.filter $('*'), (e) ->
        guid = $(e).attr('guid')
        parts = dripId.guidToDrip guid
        pred = -> parts.name == name and parts.drip == dId
        e if parts? and pred()
      found = $(_.first(els))
      found.package = -> formPackage( found )
      found

    # Eval post render function in the context
    # of a specific component
    evalPostRender = (postFn) ->
      postFnStr = $(postFn).html()
      postFnPreStr = '''
        var d = byDrip;
        var current = sel;
        var c = function (n) { return getComponent(n) };
      '''
      postFnStrPrime = "#{postFnPreStr}#{postFnStr}"
      eval postFnStrPrime

    # Transformations on all children of a component
    postProcessComponent = (c) ->
      # Create a guid on element having `drip` attribute
      attachGuidFromDripAttr = (s) ->
        did = s.attr 'drip'
        if did?
          guid = dripId.dripToGuid name, did
          s.attr 'guid', guid
      descend = (els) -> unless _.isEmpty els
        _.each els, (kid) ->
          kid = $ kid unless kid.attr?
          attachGuidFromDripAttr kid
          descend kid.children()
      descend c.children()

    # Fetch server-side markup
    sync = (afterSync) ->
      now.driprender name, (mk, postFn) ->
        comp.markup = mk
        comp.postRender = ->
          evalPostRender postFn
        afterSync() if afterSync?

    # Render markup on page
    draw = ->
      sel.html comp.markup
      postProcessComponent sel

    # Render the component
    render = (fn) ->
      sync ->
        draw()
        ev.addTo 'postRender', comp.postRender
        fn() if fn?

    # Render a component again
    # immediately replaying post render hook
    reRender = ->
      sync ->
        draw()
        comp.postRender()

    components[name] = sel
    sel.sync = sync
    sel.draw = draw
    sel.render = render
    sel.refresh = reRender
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
      barrier = comps.length
      _.each comps, (sel) ->
        renderComponent sel, ->
          fn() if fn? and --barrier == 0

  # true if a jQuery selector represents a drip object
  isDrip = (sel) -> sel.attr('drip') == 'true'

  # Create an object with form element key-value pairs
  #   name attribute: form value
  formPackage = (form) ->
    formPairs = {}
    _.each form.children(), (c) ->
      c = $(c) unless c.attr?
      nameAttr = c.attr('name')
      formPairs[nameAttr] = c.val() if nameAttr?
    formPairs

  # Basic event system
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
    clear: (g) -> delete groups[g]
  )()

  getComponent = (name) -> components[name]

  # Intial page render call
  # fn executed after all coponents are rendered
  ready: (fn) ->
    now.ready ->
      renderAll ->
        # Execute component post-render functions
        ev.allIn 'postRender'
        fn() if fn?
  # Get a drip component by name
  component: getComponent
  components: components
)()
