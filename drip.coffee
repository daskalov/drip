coffeekup = require 'coffeekup'
_ = require 'underscore'


ckup = coffeekup.render
helpers = {}
# Holds all renderable components
components = {}
# Holds all UI helper functions
uiHelpers = {}
# Reference the session store
sessionStore = null

# Router object for multi-page applications
router = null

# Helpers available to templates provided
# by any drip component
coreHelpers =
  # Ad-hoc form useful in packaging groups of
  # user-submitted values
  dripform: (dId, inner) ->
    form drip: dId, inner

# Compile post-render function
# Sent as a string to the client to be eval'd in context
compilePostRender = (comp) ->
  postHelpers =
    hardcode:
      ready: (f) -> coffeescript f
  ckup comp.client, postHelpers

# CoffeeKup render a template with extra scope
renderTemplate = (tmpl, xtra) ->
  hard = _.extend helpers,
                  coreHelpers,
                  uiHelpers,
                  drip.clientHelpers.hardcode
  ckup tmpl, _.extend(xtra, { hardcode: hard })


# Parse a cookie string into an object with key-value pairs
# representing the key-value pairs in the cookie
# Follows `connect.utils.parseCookie`
cookieParser = (str) ->
  surroundedBy = (checkStr, surr) ->
    firstChar = checkStr[0]
    lastChar = checkStr[checkStr.length]
    firstChar == lastChar == surr
  cutEdges = (s) -> s.slice 1, -1
  plusToSpace = (s) -> s.replace /\+/g, '"'
  cutQuotes = (s) ->
    isQuoted = (s) -> surroundedBy s, '"'
    s = cutEdges s if isQuoted s
    s
  splitKeyVal = (s) ->
    [k, v] = s.split /\=/
    key: k
    val: v

  ret = {}
  str.split(/[;,] */).forEach (strPair) ->
    pair = splitKeyVal strPair
    unless ret[pair.key]?
      pair.val = plusToSpace cutQuotes pair.val
      try ret[pair.key] = decodeURIComponent pair.val
      catch err
        if err instanceof URIError ret[pair.key] = pair.val
        else                       throw err
  ret


drip = exports

# Add to UI elements available to drip components
drip.ui = (els) ->
  uiHelpers = _.extend uiHelpers, els

# Capture variables from a path
drip.capture = (path) -> (matchPath, paramsHandler) ->
  params = router.parameterize matchPath, path
  if params?
    paramsHandler null, params
  else
    paramsHandler "no match"

# Main render function
# Render a drip component's template with
# the scope specified by the component in scope
drip.nowRender = (name, path, pathParams, injectedScopes, clientHandler) ->
  comp = components[name]
  scopeObj =
    # Expose capture function for this path
    capture: drip.capture path
    # Expose params captured on the client
    params: pathParams
    # Expose variables to view
    expose: (exposed...) ->
      fullScope = _.extend injectedScopes, exposed...
      markup = renderTemplate comp.render, fullScope
      clientHandler markup, compilePostRender(comp)
  comp.scope.apply scopeObj, [ scopeObj ]

# Drip helpers for templates
# Used to supply a template with the local `component`
# which accepts as an argument the name of a declared
# component to render in-place
drip.clientHelpers =
  hardcode:
    component: (name, props) ->
      props ?= {}
      props.drip = 'true'
      props.component = name
      # Structure of this tag is duplicated client-side
      # to allow for component injection without a round-trip
      # to reuse server-side definition
      div props

# Define a component object
# After declaration, the component is available
# to be rendered by name
drip.component = (compName, props) ->
  props.name = compName
  props.scope ?= (s) -> s.expose {}
  props.client ?= ->
  components[compName] = props
  props

# Retrieve session in a now context
drip.session = (ctx, sessionHandler) ->
  sessionId = ctx.socket.handshake.sessionId
  sessionStore.get sessionId, sessionHandler

# Drip initialization
# drip.init
#   now:
#     everyone: everyone
#     now: now
#   session:
#     key: key
#     store: store
#   router: router
drip.init = (props) ->
  everyone = props.now.everyone
  nowjs = props.now.now
  sessionKey = props.session.key
  sessionStore = props.session.store
  router = props.router
  # Set sessionID during handshake to expose it for render call
  nowjs.server.set 'authorization', (data, accept) ->
    cookie = data.headers.cookie
    if cookie?
      data.cookie = cookieParser cookie
      data.sessionId = data.cookie[sessionKey]
      accept null, true
    else accept 'Missing cookie. Authorization failed.', false
  # Setup the server-side now function
  # clients will call to fetch components
  everyone.now.driprender = (name, path, params, clientHandler) ->
    that = this
    # Expose client's session to render scope
    drip.session this, (err, session) ->
      unless err?
        extras =
          socket:  that.socket
          session: session
          nowuser: that.user
        extras.user = session.user if session?
        drip.nowRender name, path, params, extras, clientHandler
      else
        throw "Couldn't retrieve the session"
