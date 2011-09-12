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
      found.package = formPackage
      found

    # receive / send
    receiveEvents = eventSystem()
    # subscribe / publish
    subscribeEvents = eventSystem()

    # Convenience wrapper for jQuery .submit
    submitHelper = (accFn) -> (dId, fn) ->
      accFn(dId).submit ->
        fn()
        return false

    # Eval post render function in the context
    # of a specific component
    evalPostRender = (postFn) ->
      postFnStr = $(postFn).html()
      # Define the local interface exposed to
      # a component's post-render function
      postFnPreStr = '''
        var d         = byDrip;
        var current   = sel;
        var c         = getComponent
        var receive   = receiveEvents.add;
        var subscribe = subscribeEvents.add;
        var submit    = submitHelper(d);
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
    draw = (fn) ->
      sel.html comp.markup
      postProcessComponent sel
      ev.emit "ready-#{name}"
      fn() if fn?

    # Render the component
    # Called in initial page load
    # Subsequent rendering should use component.refresh
    render = (fn) ->
      sync ->
        draw fn

    # Render a component again
    reRender = (args = {}) ->
      sync ->
        args.before() if args.before?
        draw args.after

    sel.sync = sync
    sel.draw = draw
    sel.render = render
    sel.refresh = reRender
    sel.send = receiveEvents.emitGroup
    sel.publish = subscribeEvents.emitGroup
    sel.element = byDrip
    components[name] = sel


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
  formPackage = ->
    _.reduce @serializeArray(),
      (ret, h) ->
        ret[h.name] = h.value
        ret
      {}

  # Basic event system
  eventSystem = ->
    events = {}
    set: (name, fn) -> events[name] = fn
    emit: (name) -> events[name]() if events[name]?
    emitGroup: (name, args...) -> if events[name]?
      _.each events[name], (f) -> f args...
    add: (name, fn) -> (events[name] ||= []).push fn
  # Object for all inter-component events
  ev = eventSystem()


  # Control path state and state -> state
  # transition function invocation
  fsm = (->
    current = 'fresh'
    freshFns = {}
    transitions = {}
    currentParams = {}
    params: -> currentParams
    setFresh: (p, fn) -> freshFns[p] = fn
    transition: (props) ->
      transitions[ [props.from, props.to] ] = props.forward
      transitions[ [props.to, props.from] ] = props.reverse
    advance: (newState, params) ->
      currentParams = params
      tr = transitions[ [current, newState] ]
      freshFn = freshFns[newState]
      isFresh = current is 'fresh'
      fn = if isFresh or tr is undefined then freshFn else tr
      fn.apply this
      current = newState
  )()

  # Wrapper around PathJS to expose routing and
  # transition declarations
  router = (->
    eachPair = (c, f) ->
      _.each _.keys(c), (k) -> f k, c[k]
    fresh: fsm.fresh
    transition: fsm.transition
    route: (path, action) ->
      that = this
      that.path = path
      fsm.setFresh path, action
      Path.map('#!' + path).to ->
        fsm.advance.apply that, [path, @params]
    replace: (pairs) ->
      eachPair pairs, (replaceId, compName) ->
        drip.inject compName,
          into: $ '#' + replaceId
  )()

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
      fn.apply router if fn?
      Path.listen()
  # Get a drip component by name
  component: getComponent
  # Return all maintained components
  components: components
  # Return object of current path params
  params: fsm.params
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
