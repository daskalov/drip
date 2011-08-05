coffeekup = require 'coffeekup'
_ = require 'underscore'


helpers = {}

# Helpers available to templates provided
# by any drip component
coreHelpers =
  # Ad-hoc form useful in packaging groups of
  # user-submitted values
  dripForm: (inner) ->
    div dripform: 'true', id: 'drip_form', ->
      inner()
  # Allow a drip template to specify
  # actions to perform immediately after render
  postRender: (inner) ->
    # Set up environment before component specific calls
    coffeescript ->
      window.testInPostRender = -> alert 'am in postRender'
    # Component-specific calls
    coffeescript inner

# Holds all renderable components
components = {}

# Individual component pieces
template = (name) -> components[name].render
scopeFor = (name) -> components[name].scope

# Main render function
# Renders a drip component's template with
# the scope specified by the component in scope
nowRender = (name, markupHandler) ->
  tmpl        = template name
  extraScope = scopeFor name
  extraScope (sc) ->
    markupHandler renderTemplate(tmpl, sc)

# CoffeeKup render a template with extra scope
renderTemplate = (tmpl, xtra) ->
  hard = { hardcode: _.extend(helpers, coreHelpers) }
  coffeekup.render tmpl, _.extend(xtra, hard)

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
  components[compName] = props

# Sets the now function called by the client
drip.setNow = (errbody) ->
  errbody.now.driprender = nowRender
