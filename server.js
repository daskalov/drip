var express = require('express');
var app = express.createServer();

function simpleServer(req, res) {
  res.render('wall/list.jade');
}

app.get("/", simpleServer);

app.listen(3000);
