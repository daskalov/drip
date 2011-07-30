coffeekup = require 'coffeekup'
_ = require 'underscore'

helpers = {}

# Holds all renderable components
components = {}

# Individual component pieces
template = (name) -> components[name].render
scopeFor = (name) -> components[name].scope

# Function to supply to everyone.now.render
nowRender = (name, cbak) ->
  tmpl = template name
  extra_scope = scopeFor name
  extra_scope (sc) ->
    cbak renderTemplate(tmpl, sc)

# CoffeeKup render a template with extra scope
renderTemplate = (tmpl, xtra) ->
  coffeekup.render tmpl, hardcode: _.extend(helpers, xtra)

# PUBLIC API
civet = exports

# Adds a component to the components object
civet.component = (compName, props) ->
  props.scope ?= (s) -> s {}
  components[compName] = props
# Sets the now function called by the client
civet.setNow = (errbody) ->
  errbody.now.render = nowRender
