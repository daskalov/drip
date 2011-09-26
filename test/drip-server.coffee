vows = require 'vows'
should = require 'should'
drip = require '../drip'
nowjs = require 'now'
express = require 'express'

app = express.createServer()
everyone = nowjs.initialize app
drip.init
  now:
    everyone: everyone
    now: nowjs

vows.describe('Drip Server')
.addBatch
 'Exposes a public interface': ->
   should.exist drip.ui
   should.exist drip.capture
   should.exist drip.nowRender
   should.exist drip.clientHelpers
   drip.clientHelpers.should.have.property 'hardcode'
   drip.clientHelpers.hardcode.should.have.property 'component'
   should.exist drip.component
   should.exist drip.session

 'regular component':
   topic: drip.component 'test:component'
     render: ->
       h1 'Big text'
       h2 "#{@a}"
       h2 @b
     scope: (s) ->
       s.expose { a: '1', b: '2' }
     client: -> ready ->
       alert 'Hey'
   'gives it a name': (component) ->
     component.should.have.property 'name'
   'and rendering':
     topic: (component) ->
       drip.nowRender name: component.name, @callback
     'generates markup': (mk, p) ->
       should.exist mk
       mk.should.be.a 'string'
     'exposes the local scope': (mk, p) ->
       mk.should.include.string '<h2>1</h2>'
       mk.should.include.string '<h2>2</h2>'

  'component with arguments':
    topic: drip.component 'test:args'
      render: ->
        p @foo
      scope: -> @expose @args
    'and rendering with arguments':
      topic: (component) ->
        drip.nowRender
          name: component.name
          args:
            foo: 'bear'
          ,
          @callback
      'renders arguments': (mk, p) ->
        mk.should.include.string 'bear'

  'component depending on params':
    topic: drip.component 'test:params'
      render: ->
        h1 'hey'
        h1 @a
        h2 @b
      scope: -> @expose @params
    'and rendering with parameters':
      topic: (component) ->
        drip.nowRender
          name: component.name
          params:
            a: '1'
            b: '2'
          ,
          @callback
      'renders parameters': (mk, p) ->
        mk.should.include.string '<h1>1'
        mk.should.include.string '<h2>2'

 'view-only component':
   topic: drip.component 'test:viewonly'
     render: -> h1 'Not much here'
   'gives it a default empty scope': (component) ->
     component.should.have.property 'scope'
   'gives it a default post render function': (component) ->
     component.should.have.property 'client'

.export module
