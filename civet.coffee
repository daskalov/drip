coffeekup = require 'coffeekup'
_ = require 'underscore'

helpers = {}

coreHelpers =
  someVal: 'a val in core helpers'

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
  coffeekup.render tmpl,
    hardcode: _.extend(helpers, coreHelpers, xtra)

# PUBLIC API
civet = exports

# Civet helpers for templates
civet.clientHelpers =
  hardcode:
    component: (name) ->
      div civet: 'true', component: name

# Adds a component to the components object
civet.component = (compName, props) ->
  props.scope ?= (s) -> s {}
  components[compName] = props

# Sets the now function called by the client
civet.setNow = (errbody) ->
  errbody.now.render = nowRender
