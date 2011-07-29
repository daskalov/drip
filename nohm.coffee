redis = require 'redis'
nohm = require('Nohm').Nohm
client = redis.createClient()
nohm.setClient(client)

Wall = nohm.model 'Wall'
  properties:
    name:
      type: 'string'
      defaultValue: 'default-wall-name'
    key:
      type: 'integer'

wallFinder = new Wall()
allWalls = (cbak) ->
  wallFinder.find (err, ids) ->
    cbak ids.sort()
wallById = (id, cbak) ->
  newW = new Wall()
  newW.load id, (err) ->
    console.log err if err?
    console.log "id: #{id}"
    cbak newW

listNames = ->
  allWalls (ids) ->
    ids.forEach (id) ->
      wallById id, (w) -> console.log w.p('name')

allWallObjects = (cbak) ->
  nm = []
  allWalls (ids) ->
    ids.forEach (id) ->
      wallById id, (w) ->
        nm.push w
        cbak nm if nm.length >= ids.length

getNames = (cbak) ->
  allWallObjects (obs) ->
    cbak obs.map (o) -> o.p('name')


# allWallObjects (ww) -> console.log ww
getNames (nm) -> console.log nm
