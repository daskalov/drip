String.prototype.byId = -> $('#' + this)
String.prototype.component = -> drip.component(@)

drip.ready ->
  drip.events.all()
  # onClick 'button'
    # send:    -> drip.formPackage 'wall'
    # to:      now.makeWall
    # refresh: 'walls:list'

# Specify a call from within a component
# Attach these helpers to client drip
# ? Can generate callable client scripts with the template
#   helpers directly so that good functions exist when needed?
onClick = (bid, props) ->
  bid.byId().click ->
    props.to props.send(), ->
      props.refresh.component().render()

now.clientTest = -> alert 'got clientTest called'

now.wallBind = (serverStr) ->
  alert 'having wallBind called'
  eval(serverStr)
  ff()
  alert 'just called server cbak'

# now.core.on 'disconnect', -> alert "Now.JS disconnected!"
# now.clientConnect = ->
  # alert 'NowJs saw me connect'

