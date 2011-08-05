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
drip = require './drip'
drip.setNow everyone
# Mongoose init
mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/test'


# Mongoose
Wall = new mongoose.Schema
  name:
    type: String
    default: 'default-name'
  description:
    type: String
    default: 'None Given.'
mongoose.model 'Wall', Wall
WallModel = mongoose.model 'Wall'

WallModel.all = (cbak) ->
  WallModel.find {}, (err, docs) ->
    if err? cbak err
    else    cbak docs.reverse()

WallModel.makeWall = (props, cbak) ->
  w = new WallModel()
  w.name = props.name
  w.description = props.description
  w.save (err) ->
    if err? cbak err
    else    cbak 'Saved!'


# Now
everyone.now.makeWall = WallModel.makeWall

everyone.now.test = (fromClient) ->
  cid = @user.clientId
  console.log "Got #{fromClient} from client"
  console.log "cid: #{cid}"
  everyone.now.clientTest()

everyone.now.bindStuff = ->
  @now.wallBind "var ff = function () { return alert('From se!'); }"

# nowjs.on 'connect', -> this.now.clientConnect()


# Drip
drip.component 'walls:add'
  render: ->
    dripForm ->
      input id: 'wall_name', drip: 'wall-name', name: 'name'
      input id: 'wall_description', drip: 'desc', name: 'description'
    a id: 'button', href: "#", drip: 'button', ->
      '+ Add'

drip.component 'walls:list'
  render: ->
    h4 "#{ @walls.length }"
    a id: 'test_button', 'Test'
    ul ->
      @walls.forEach (w) ->
        li w.name
        li w.description
        br ''

    postRender -> drip.events.add ->
      alert 'a'
      alert 'b'

  scope: (s) ->
    WallModel.all (docs) ->
      s walls: docs

# Router
app.get '/', (req, res) ->
  res.render 'wall/drip', drip.clientHelpers

app.listen 3000
