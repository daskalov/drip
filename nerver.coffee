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
civet = require './civet'
civet.setNow everyone

# Nohm
Wall = nohm.model 'Wall'
  properties:
    name:
      type: 'string'
      defaultValue: 'default-wall-name'
    key:
      type: 'integer'
allWalls = (cbak) ->
  wallFinder = new Wall()
  wallFinder.find (err, ids) ->
    cbak ids
wallById = (id, cbak) ->
  newW = new Wall()
  newW.load id, (err) ->
    console.log err if err?
    cbak newW
allWallObjects = (cbak) ->
  nm = []
  allWalls (ids) ->
    ids.forEach (id) ->
      wallById id, (w) ->
        nm.push w
        cbak nm if nm.length >= ids.length
wallNames = (cbak) ->
  allWallObjects (obs) ->
    cbak obs.map (o) -> o.p('name')

makeLookLikeObject = (obs) ->
  obs.map (o) -> name: o.p('name')

everyone.now.makeWall = (name, description, cbak) ->
  w = new Wall()
  w.p('name', name)
  w.p('description', description)
  w.save (err) ->
    if err
      cbak err
    else
      cbak 'Great!'

# Civet client definitions
civet.component 'walls:add'
  render: ->
    input id: 'wall_add'
    a id: 'wall_add_button', href: "#", ->
      '+ Add'

civet.component 'walls:list'
  render: ->
    ul ->
      walls.forEach (w) ->
        li w.name
  scope: (retScope) ->
    allWallObjects (obs) ->
      retScope walls: makeLookLikeObject obs


# Router
app.get '/', (req, res) ->
  res.render 'wall/civet', civet.clientHelpers

app.listen 3000
