vows = require 'vows'
should = require '/Users/alexd/dev/javascript/should.js'
drip = require '../drip'
nowjs = require 'now'
express = require 'express'
everyone = nowjs.initialize express.createServer()
drip.setNow everyone

vows.describe('Drip Server').addBatch(

  'Exposes a public interface':
    'nowRender': ->
      should.exist drip.nowRender
    'clientHelpers': ->
      should.exist drip.clientHelpers
      drip.clientHelpers.should.have.property 'hardcode'
      drip.clientHelpers.hardcode.should.have.property 'component'
    'component': ->
      should.exist drip.component
    'setNow': ->
      should.exist drip.setNow
      should.exist everyone.now.driprender

  'Creating a component':
    topic: drip.component 'test:component'
      render: ->
        h1 'Big text'
        h2 "#{@a}"
        h2 @b
      scope: (s) ->
        s { a: 1, b: '2' }
      client: -> ready ->
        alert 'Hey'

    'gives it a name': (component) ->
      component.should.have.property 'name'

    'exposes a non-empty scope': (component) ->
      component.scope (s) -> s.should.eql { a: '1', b: '2' }

    'and rendering':
      topic: (component) ->
        drip.nowRender component.name, @callback

      'generates markup': (mk, p) ->
        should.exist mk
        mk.should.be.a 'string'

      'exposes the local scope': (mk, p) ->
        mk.should.include.string '<h2>1</h2>'
        mk.should.include.string '<h2>2</h2>'

  'Creating a view-only component':
    topic: drip.component 'test:viewonly'
      render: -> h1 'Not much here'

    'Gives it a default empty scope': (component) ->
      component.should.have.property 'scope'
      component.scope (s) -> s.should.eql {}

    'Gives it a default post render function': (component) ->
      component.should.have.property 'client'

).export(module)
