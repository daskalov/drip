drip = window.drip = (->
  components = {}

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

  # Apply fn recursively to every child of sel
  applyToAllChildren = (sel, fn) ->
    descend = (els) -> unless _.isEmpty els
      _.each els, (kid) ->
        kid = $ kid unless kid.attr?
        fn kid
        descend kid.children()
    descend sel.children()

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

    # receive / send
    receiveEvents = eventSystem()
    # subscribe / publish
    subscribeEvents = eventSystem()

    # Eval post render function in the context
    # of a specific component
    evalPostRender = (postFn) ->
      postFnStr = $(postFn).html()
      postFnPreStr = '''
        var d = byDrip;
        var current = sel;
        var c = getComponent
        var receive = receiveEvents.add;
        var subscribe = subscribeEvents.add;
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
      applyToAllChildren c, attachGuidFromDripAttr

    # Fetch server-side data
    sync = (afterSync) ->
      hash = window.location.hash
      now.driprender name, hash, (mk, postFn) ->
        comp.markup = mk
        comp.postRender = ->
          # Render any nested components
          renderAllIn sel
          # Execute component's ready function
          evalPostRender postFn
        ev.set "ready-#{name}", comp.postRender
        afterSync() if afterSync?

    # Render markup on page
    draw = ->
      sel.html comp.markup
      postProcessComponent sel
      ev.emit "ready-#{name}"

    # Render the component
    # Called in initial page load
    # Subsequent rendering should use component.refresh
    render = (fn) ->
      sync ->
        draw()
        fn() if fn?

    # Render a component again
    reRender = (args = {}) ->
      sync ->
        args.before() if args.before?
        draw()
        args.after() if args.after?

    components[name] = sel

    sel.sync = sync
    sel.draw = draw
    sel.render = render
    sel.refresh = reRender
    sel.send = receiveEvents.emitGroup
    sel.publish = subscribeEvents.emitGroup
    sel


  # Render a single component from a jQuery selector
  renderComponent = (sel, fn) ->
    comp = component sel
    comp.render fn

  # Returns a flat array of every child of sel
  flattenChildren = (sel) ->
    all = []
    applyToAllChildren sel, (c) -> all.push c
    all

  # Retrieve all drip components that are children of sel
  componentsIn = (sel) ->
    _.filter flattenChildren(sel), isDrip

  # Render any components that are children of sel
  renderAllIn = (sel, fn) ->
    comps = componentsIn sel
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
  eventSystem = ->
    events = {}
    set: (name, fn) -> events[name] = fn
    emit: (name) -> events[name]() if events[name]?
    emitGroup: (name) -> if events[name]?
      _.each events[name], (f) -> f()
    add: (name, fn) -> (events[name] ||= []).push fn
  # Object for all inter-component events
  ev = eventSystem()

  # Retrieve a component by name
  getComponent = (name) -> components[name]

  # Create an empty component container
  # NOTE: Client dupliacte of helper in `drip.clientHelpers`
  componentTemplate = (compName) -> """
    <div component="#{compName}" drip="true">
    </div>
  """

  # Intial render for multi-page applications
  pageRender: (fn) ->
    now.ready ->
      renderAllIn $('body'), fn
  # Initial render for single-page applications
  start: (fn) ->
    now.ready ->
      fn() if fn?
  # Get a drip component by name
  component: getComponent
  # Return all maintained components
  components: components
  # Publish a message for all subscribed
  publish: (name) ->
    _.each components, (c) -> c.publish name
  # Inject a component into an element
  inject: (compName, props) ->
    into = props.into
    compContainer = componentTemplate compName
    comp = component $(compContainer)
    into.html comp
    comp.refresh props
)()
