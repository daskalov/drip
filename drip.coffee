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
  dripForm: (dId, inner) ->
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
  hard =
    hardcode: _.extend helpers,
                       coreHelpers,
                       uiHelpers
  ckup tmpl, _.extend(xtra, hard)


drip = exports

# Add to UI elements available to drip components
drip.ui = (els) ->
  uiHelpers = _.extend uiHelpers, els

# Main render function
# Render a drip component's template with
# the scope specified by the component in scope
drip.nowRender = (name, clientHandler) ->
  comp = components[name]
  comp.scope (sc) ->
    markup = renderTemplate(comp.render, sc)
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

# Set the now function called by the client
drip.setNow = (errbody) ->
  errbody.now.driprender = drip.nowRender
