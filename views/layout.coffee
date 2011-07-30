html ->
  head ->
    title @title or "Hey there"
    link rel: 'stylesheet', href: '/style/master.css'
    script src: '/javascript/jquery.min.js'
    script src: '/javascript/underscore-min.js'
    script src: '/nowjs/now.js'
    script src: '/javascript/coffeescript.js'
    script src: '/javascript/coffeekup.js'
    script src: '/javascript/civet-client.js'
    script src: '/javascript/client.js'
  body ->
    div class: 'container', ->
      div class: 'inner_container', ->
        @body
