drip = window.drip = (->
  components = {}
  uniqueNum = 0

  # Apply fn recursively to every child of sel
  applyToAllChildren = (sel, fn) ->
    descend = (els) -> unless _.isEmpty els
      _.each els, (kid) ->
        kid = $ kid unless kid.attr?
        fn kid
        descend kid.children()
    descend sel.children()

  # Retrieve name of a component from a selector
  nameFromSel = (sel) -> sel.attr 'component'

  # Augment jQuery selector with drip properties
  # Represents a single drip component
  component = (sel, compArgs) ->
    comp = sel.drip = {}
    name = nameFromSel sel
    comp.args = compArgs if compArgs?

    # Set unique string used to disambiguate
    # components with the same name
    unique = String ++uniqueNum

    # Mappings between drip ids relative to a
    # component and guids held on element attributes
    dripId =
      SEPERATOR: '___'
      dripToGuid: (cname, dripId) ->
        cname + @SEPERATOR + dripId + @SEPERATOR + unique
      guidToDrip: (gu) ->
        return undefined unless gu?
        [nm, dId, u] = gu.split @SEPERATOR
        name: nm
        drip: dId
        unique: u

    # Retrieve an element from the component by drip id
    byDrip = (dId) ->
      els = _.filter $('*'), (e) ->
        guid = $(e).attr('guid')
        parts = dripId.guidToDrip guid
        e if parts? and
          parts.name is name and
          parts.drip is dId and
          parts.unique is unique
      found = $ els
      found.package = formPackage
      found

    # receive / send
    receiveEvents = eventSystem()
    # subscribe / publish
    subscribeEvents = eventSystem()
    # setup / teardwon
    lifecycleEvents = eventSystem()

    # Eval post render function in the context
    # of a specific component
    evalPostRender = (postFn) ->
      # Convenience wrapper for jQuery .submit
      submitHelper = (accFn) -> (dId, fn) ->
        el = accFn dId
        el.unbind('submit').submit ->
          fn()
          return false
      # Curry lifecycle setting
      lifecycleSet = (evName) -> (fn) ->
        lifecycleEvents.set evName, fn
      postFnStr = $(postFn).html()
      # Define the local interface exposed to
      # a component's post-render function
      postFnPreStr = '''
        var d         = byDrip;
        var current   = sel;
        var c         = getComponent
        var receive   = receiveEvents.set;
        var subscribe = subscribeEvents.set;
        var setup     = lifecycleSet('setup');
        var teardown  = lifecycleSet('teardown');
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
      pr =
        name: name
        hash: hash
        params: drip.params()
        args: compArgs
      now.driprender pr, (mk, postFn) ->
        comp.markup = mk
        comp.postRender = ->
          # Render any nested components
          renderAllIn sel
          # Execute component's ready function
          evalPostRender postFn
          # Execute any component setup
          sel.setup()
        ev.set "ready-#{name}", comp.postRender
        afterSync() if afterSync?

    # Render markup on page
    draw = (fn) ->
      sel.html comp.markup
      postProcessComponent sel
      ev.emit "insert-#{name}"
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


    sel.args     = comp.args
    sel.sync     = sync
    sel.draw     = draw
    sel.render   = render
    sel.refresh  = reRender
    sel.send     = receiveEvents.emit
    sel.publish  = subscribeEvents.emit
    sel.setup    = -> lifecycleEvents.emit 'setup'
    sel.teardown = -> lifecycleEvents.emit 'teardown'
    sel.element  = byDrip
    components[name] = sel


  # Returns a flat array of every child of sel
  flattenChildren = (sel) ->
    all = []
    applyToAllChildren sel, (c) -> all.push c
    all

  # Retrieve all drip components that are children of sel
  componentsIn = (sel) ->
    _.filter flattenChildren(sel), isDrip

  # Iterate over each loaded drip component
  # that is a child of sel
  eachComponentIn = (sel, compHandler) ->
    all = componentsIn sel
    _.each all, (s) ->
      compHandler drip.component nameFromSel s

  # Render a single component from a jQuery selector
  renderComponent = (sel, fn) ->
    comp = component sel
    comp.render fn

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
    emit: (name, args...) ->
      events[name] args... if events[name]?
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

  # Util
  # Return a function calling a
  # collection of functions in turn
  cyclicApply = (fns, start = 0) -> ->
    fns[start++ % fns.length]()

  # Alternate calling one of two functions
  alternate = (fns) -> cyclicApply [fns.a, fns.b]

  # Create a simple linked list
  arrayToList = (arr) ->
    lastVisited = {}
    m = []
    _.each arr, (e) ->
      lastVisited.next = node =
        value: e
        prev: lastVisited
      m.push e = lastVisited = node
    (_.first m).prev = _.last m
    (_.last  m).next = _.first m
    m

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
  # Refresh the entire page
  refreshPage: -> _.each components, (c) ->
    c.refresh()
  # Return object of current path params
  params: fsm.params
  # Publish a message for all subscribed
  publish: (name) ->
    _.each components, (c) -> c.publish name
  # Go to some path
  to: (p) -> window.location.hash = '#!/' + p

  # UI functions
  # Basic wizard helper
  wizard: (d, name, p) ->
    panes = _.map p.states, d
    curr = _.last arrayToList panes
    change = (dir) -> ->
      curr = curr[dir]
      d(name).html curr.value.html()
    next: change 'next'
    prev: change 'prev'

  # Toggle between some markup and a component
  toggler: (p) ->
    fwd = p.transition && p.transition.forward
    rev = p.transition && p.transition.reverse
    prerev = p.transition && p.transition.preReverse
    both = p.transition && p.transition.both
    old = null
    alternate
      a: ->
        old = p.from.html()
        p.inject ||= {}
        p.inject.into = p.from
        drip.inject p.to, p.inject
        fwd() if fwd?
        both() if both?
      b: ->
        action = -> p.from.html old
        if prerev? then prerev action else action()
        rev() if rev?
        both() if both?

  # Inject a component into an element
  inject: (compName, props) ->
    into = props.into
    compContainer = componentTemplate compName
    comp = component $(compContainer), props.args
    ev.set "insert-#{compName}", ->
      eachComponentIn into, (c) -> c.teardown()
      into.html comp
    comp.refresh props
)()
