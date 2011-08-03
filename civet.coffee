coffeekup = require 'coffeekup'
_ = require 'underscore'


helpers = {}
coreHelpers = {}

# Holds all renderable components
components = {}

# Individual component pieces
template = (name) -> components[name].render
scopeFor = (name) -> components[name].scope

# Function to supply to everyone.now.render
nowRender = (name, markupHandler) ->
  tmpl        = template name
  extra_scope = scopeFor name
  extra_scope (sc) ->
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
