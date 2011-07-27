civet = exports
coffeekup = require 'coffeekup'
_ = require 'underscore'

helpers = {}

exports.civet = civet =
  # Holds all renderable components
  components: {}
  # Adds a component to the components object
  component: (compName, props) ->
    civet.components[compName] = props
  # Individual component pieces
  template: (name) -> civet.components[name].render
  scopeFor: (name) -> civet.components[name].scope
  # CoffeeKup render a template with extra scope
  renderTemplate: (tmpl, xtra) ->
    coffeekup.render tmpl, hardcode: _.extend(helpers, xtra)
  # Function to supply to everyone.now.render
  nowRender: (name, cbak) ->
    template = civet.template name
    extra_scope = civet.scopeFor name
    extra_scope (sc) ->
      cbak(civet.renderTemplate(template, sc))
  # Sets the now function called by the client
  setNow: (errbody) ->
    errbody.now.render = civet.nowRender
