coffeekup = require 'coffeekup'
_ = require 'underscore'


ckup = coffeekup.render
helpers = {}
# Holds all renderable components
components = {}
# Holds all UI helper functions
uiHelpers = {}

# Helpers available to templates provided
# by any drip component
coreHelpers =
  # Ad-hoc form useful in packaging groups of
  # user-submitted values
  dripform: (dId, inner) ->
    attrs = {}
    attrs.drip = dId
    attrs.dripform = 'true'
    attrs.id = 'drip_form'
    div attrs, inner

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


drip = exports

# Add to UI elements available to drip components
drip.ui = (els) ->
  uiHelpers = _.extend uiHelpers, els

# Main render function
# Render a drip component's template with
# the scope specified by the component in scope

drip.nowRender = (name, injectedScopes, clientHandler) ->
  comp = components[name]
  comp.scope (sc) ->
    fullScope = _.extend sc, injectedScopes
    markup = renderTemplate(comp.render, fullScope)
    clientHandler markup, compilePostRender(comp)

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
  props.scope ?= (s) -> s {}
  props.client ?= ->
  components[compName] = props
  props


# Drip initialization
# drip.init
#   now:
#     everyone: everyone
#     now: now
#   session:
#     key: key
#     store: store
drip.init = (props) ->
  everyone = props.now.everyone
  nowjs = props.now.now
  sessionKey = props.session.key
  sessionStore = props.session.store
  # Set sessionID during handshake to expose it for render call
  nowjs.server.set 'authorization', (data, accept) ->
    cookie = data.headers.cookie
    if cookie?
      data.cookie = utils.cookieParser cookie
      data.sessionId = data.cookie[sessionKey]
      accept null, true
    else accept 'Missing cookie. Authorization failed.', false
  # Setup the server-side now function
  # clients will call to fetch components
  everyone.now.driprender = (name, clientHandler) ->
    # Grab the client's session exposing it to
    # the component render scope
    sessionId = @socket.handshake.sessionId
    that = this
    sessionStore.get sessionId, (err, session) ->
      unless err?
        extraScopes =
          socket:  that.socket
          session: session
          nowuser: that.user
        extraScopes.user = session.user if session?
        drip.nowRender(name, extraScopes, clientHandler)
      else
        throw "Couldn't retrieve the session"

utils =
  # Parse a cookie string into an object with key-value pairs
  # representing the key-value pairs in the cookie
  cookieParser: (str) ->
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
