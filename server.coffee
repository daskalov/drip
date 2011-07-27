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
civet = require('./civet').civet
civet.setNow(everyone)

# Nohm
Wall = nohm.model 'Wall'
  properties:
    name:
      type: 'string'
      defaultValue: 'default-wall-name'
    key:
      type: 'integer'

wallFinder = new Wall()

# Civet client definitions
civet.component 'walls:list'
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


# Router
app.get '/', (req, res) ->
  res.render 'wall/civet'
app.listen 3000
