express   = require 'express'
coffeekup = require 'coffeekup'
redis     = require 'redis'
nohm      = require('Nohm').Nohm
nowjs     = require 'now'
_         = require 'underscore'
app = express.createServer()
app.register '.coffee', require('coffeekup')
app.set 'view engine', 'coffee'
app.use express.static(__dirname + '/public')
client = redis.createClient()
nohm.setClient(client)
everyone = nowjs.initialize app

# Nohm
Wall = nohm.model 'Wall'
  properties:
    name:
      type: 'string'
      defaultValue: 'default-wall-name'
    key:
      type: 'integer'

wallFinder = new Wall()

# CoffeeKup
helpers = {}

# Civet object
Civet =
  # Holds all renderable components
  components: {}
  # Adds a component to the components object
  component: (compName, props) ->
    Civet.components[compName] = props
  # Get a template by name
  template: (name) -> Civet.components[name].render
  # Get the extra scope for some template
  scopeFor: (name) -> Civet.components[name].scope
  # CoffeeKup render a template with extra scope
  renderTemplate: (tmpl, xtra) ->
    coffeekup.render tmpl, hardcode: _.extend(helpers, xtra)
  # Function to supply to everyone.now.render
  nowRender: (name, cbak) ->
    template = Civet.template name
    extra_scope = Civet.scopeFor name
    extra_scope (sc) ->
      cbak(Civet.renderTemplate(template, sc))
  # Sets the now function called by the client
  setNow: (errbody) ->
    errbody.now.render = Civet.nowRender


# Civet client definitions
Civet.component 'walls:list'
  render: ->
    ul ->
      li 'one 1'
      li 'two 2'
    ul ->
      for ann in animals
        li ann
    ul ->
      for ii in ids
        li ids
  scope: (retScope) ->
    wallFinder.find (err, ids) ->
      retScope { ids: ids, animals: ['cat', 'dog', 'pig'] }



# Now
Civet.setNow(everyone)

# Router
app.get '/', (req, res) ->
  res.render 'wall/civet'
    hardcode: helpers
app.listen 3000
