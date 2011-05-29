var express = require('express');
var app = express.createServer();

function simpleServer(req, res) {
  res.send("You see me");
}

app.get("/", simpleServer);

app.listen(3000);
