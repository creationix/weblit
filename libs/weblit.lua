--[[lit-meta
  name = "creationix/weblit"
  version = "3.1.2"
  dependencies = {
    "creationix/weblit-app@3.0.0",
    "creationix/weblit-auto-headers@2.0.2",
    "creationix/weblit-etag-cache@2.0.0",
    "creationix/weblit-logger@02.0.0",
    "creationix/weblit-cors@2.0.0",
    "creationix/weblit-static@2.2.2",
    "creationix/weblit-websocket@3.0.0",
    "creationix/weblit-force-https@2"
  }
  files = {
    "package.lua",
    "init.lua",
  }
  description = "This Weblit metapackage brings in all the official Weblit modules."
  tags = {"weblit", "meta"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit"
--]]

return {
  app = require('weblit-app'),
  autoHeaders = require('weblit-auto-headers'),
  etagCache = require('weblit-etag-cache'),
  logger = require('weblit-logger'),
  static = require('weblit-static'),
  websocket = require('weblit-websocket'),
}
