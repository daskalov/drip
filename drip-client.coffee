drip = window.drip = (->
  components = {}
  renderedOnce = false

  # Mappings between drip ids relative to a
  # component and guids held on element attributes
  dripId =
    GUID_SEPERATOR: '___'
    dripToGuid: (cname, dripId) ->
      "#{cname}#{@GUID_SEPERATOR}#{dripId}"
    guidToDrip: (gu) ->
      return undefined unless gu?
      [nm, dId] = gu.split @GUID_SEPERATOR
      name: nm
      drip: dId

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
        e if parts? and parts.name is name and parts.drip is dId
      found = $ _.first els
      found.package = -> formPackage found
      found

    # All subscribed events for this component
    subEvents = {}
    # Function for post-render event subscription
    subscribeToEvent = (name, respondFn) ->
      subEvents[name] = respondFn
    # Invoke component event by name
    fireEvent = (name) -> subEvents[name]()

    # Eval post render function in the context
    # of a specific component
    evalPostRender = (postFn) ->
      postFnStr = $(postFn).html()
      postFnPreStr = '''
        var d = byDrip;
        var current = sel;
        var c = function (n) { return getComponent(n) };
        var subscribe = subscribeToEvent;
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

    # Fetch server-side data
    sync = (afterSync) ->
      now.driprender name, (mk, postFn) ->
        comp.markup = mk
        # When called, `comp.postRender` will execute the code supplied
        # by the component's `client: -> ready ->` definition
        comp.postRender = ->
          evalPostRender postFn
        afterSync() if afterSync?

    # Render markup on page
    draw = ->
      sel.html comp.markup
      postProcessComponent sel

    # Render the component
    # Called in initial page load
    # Subsequent rendering should use component.refresh
    render = (fn) ->
      sync ->
        draw()
        # Accrue post-render hooks to call at once when
        # every component has rendered
        ev.addTo 'postRender', comp.postRender
        fn() if fn?

    # Render a component again
    # Immediately replay post-render hook
    reRender = (args = {}) ->
      sync ->
        args.before() if args.before?
        draw()
        comp.postRender()
        args.after() if args.after?

    components[name] = sel

    sel.sync = sync
    sel.draw = draw
    sel.render = render
    sel.refresh = reRender
    sel.send = fireEvent
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

  # Create an empty component container
  # NOTE: Client dupliacte of helper in `drip.clientHelpers`
  componentTemplate = (compName) -> """
    <div component="#{compName}" drip="true">
    </div>
  """

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
  inject: (compName, props) ->
    into = props.into
    compContainer = componentTemplate compName
    comp = component $(compContainer)
    into.html comp
    comp.refresh props
)()
