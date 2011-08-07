String.prototype.byId = -> $('#' + this)
String.prototype.component = -> drip.component(@)

drip.ready ->

onClick = (bid, props) ->
  bid.byId().click ->
    props.to props.send(), ->
      props.refresh.component().render()
