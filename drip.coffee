coffeekup = require 'coffeekup'
_ = require 'underscore'


ckup = coffeekup.render
helpers = {}
# Holds all renderable components
components = {}

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

# Main render function
# Renders a drip component's template with
# the scope specified by the component in scope
nowRender = (name, clientHandler) ->
  comp = components[name]
  comp.scope (sc) ->
    markup = renderTemplate(comp.render, sc)
    clientHandler markup, compilePostRender(comp)

# Compile post-render function
# Sent as a string to the client to be eval'd in context
compilePostRender = (comp) ->
  postHelpers =
    hardcode:
      run: (f) -> coffeescript f
  ckup comp.postRender, postHelpers

# CoffeeKup render a template with extra scope
renderTemplate = (tmpl, xtra) ->
  hard = { hardcode: _.extend(helpers, coreHelpers) }
  ckup tmpl, _.extend(xtra, hard)


drip = exports

# Drip helpers for templates
drip.clientHelpers =
  hardcode:
    component: (name, props) ->
      props ?= {}
      props.drip = 'true'
      props.component = name
      div props

# Adds a component to the components object
drip.component = (compName, props) ->
  props.scope ?= (s) -> s {}
  props.postRender ?= ->
  components[compName] = props

# Sets the now function called by the client
drip.setNow = (errbody) ->
  errbody.now.driprender = nowRender
