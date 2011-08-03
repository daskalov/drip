# Express init
express = require 'express'
app = express.createServer()
app.use express.static(__dirname + '/public')
# CoffeeKup init
coffeekup = require 'coffeekup'
app.register '.coffee', require('coffeekup')
app.set 'view engine', 'coffee'
# Now init
nowjs = require 'now'
everyone = nowjs.initialize app
# Drip init
drip = require './civet'
drip.setNow everyone
# Mongoose init
mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/test'


# Mongoose
Wall = new mongoose.Schema
  name:
    type: String
    default: 'default-name'
mongoose.model 'Wall', Wall
WallModel = mongoose.model 'Wall'

allWalls = (cbak) ->
  WallModel.update()
  WallModel.find {}, (err, docs) ->
    if (err?)
      cbak err
    else
      cbak docs.reverse()

everyone.now.makeWall = (name, description, cbak) ->
  w = new WallModel()
  w.name = name
  w.description = description
  w.save (err) ->
    if err?
      cbak err
    else
      cbak 'Saved!'


# Drip client definitions
drip.component 'walls:add'
  render: ->
    input id: 'wall_add_input'
    a id: 'wall_add_button', href: "#", ->
      '+ Add'

drip.component 'walls:list'
  render: ->
    h4 "#{ @walls.length }"
    ul ->
      @walls.forEach (w) ->
        li w.name
  scope: (retScope) ->
    allWalls (docs) ->
      retScope walls: docs

# Router
app.get '/', (req, res) ->
  res.render 'wall/civet', drip.clientHelpers

app.listen 3000
