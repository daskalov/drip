civet = window.civet = (->
  components = {}

  # Augment jQuery selector with civet properties
  component = window.component = (sel) ->
    comp = sel.civet = {}

    name = sel.attr('component')

    # Fetch server-side markup
    sync = (afterSync) ->
      now.civetrender name, (mk) ->
        comp.markup = mk
        afterSync() if afterSync?

    draw = ->
      sel.html comp.markup

    render = (fn) ->
      sync ->
        draw()
        fn() if fn?

    sel.sync = sync
    sel.draw = draw
    sel.render = render
    components[name] = sel
    sel


  # Render a single component from a jQuery selector
  renderComponent = (sel, fn) ->
    comp = component(sel)
    comp.render fn

  # Render all civet components on the page
  renderAll = (fn) ->
    els = _.map($('*'), (e) -> $(e))
    comps = _.filter els, (e) -> isCivet e
    i = 0 # hacky indexing
    _.each comps, (sel) ->
      renderComponent sel, ->
        fn() if fn? and ++i == comps.length

  # true if a jQuery selector represents a civet object
  isCivet = (sel) -> sel.attr('civet') == 'true'

  # PUBLIC INTERFACE
  {
    ready: (fn) ->
      now.ready ->
        renderAll fn

    refresh: renderAll
  }
)()


# # Augment jQuery selector with civet properties
# component = window.component = (sel) ->
#   comp = sel.civet = {}
#   name = -> sel.attr('component')
#   # Fetch server-side markup
#   sync = (afterSync) ->
#     now.civetrender name(), (mk) ->
#       comp.markup = mk
#       afterSync() if afterSync?
#   draw = ->
#     sel.html comp.markup
#   render = ->
#     sync -> draw()
#   # interface
#   sel.sync = sync
#   sel.draw = draw
#   sel.render = render
#   sel



# renderTest = ->
#   slist = $('#list')
#   clist = component(slist)
#   sadd = $('#add')
#   cadd = component(sadd)
#   clist.render()
#   cadd.render()




#    component = window.component = (->
#      name = undefined
#      markup = undefined
#    
#      # Fetch markup
#      sync = (afterSync) ->
#        nm ?= @attr('component')
#        now.civetrender nm, (mk) ->
#          @markup = mk
#          afterSync() if afterSync?
#    
#      # Draw into parent selector
#      draw = ->
#        @html @markup
#    
#      # Freshly render component
#      render = ->
#        @sync -> @draw()
#    
#      # Constructor
#      # Augment a jQuery selector with civet functions
#      # ctor = (sel) -> _.extend(
#        # sel,
#        # { sync: sync, render: render, draw: draw }
#      # )
#      # { create: ctor }
#      {
#        create: (sel) ->
#          that = _.clone(sel)
#          that.sync = sync
#          that.draw = draw
#          that.render = render
#          that
#      }
#    )()
