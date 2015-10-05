return {
  name = "creationix/weblit",
  version = "0.3.4",
  dependencies = {
    "creationix/weblit-app@0.3.0",
    "creationix/weblit-auto-headers@0.1.2",
    "creationix/weblit-etag-cache@0.1.1",
    "creationix/weblit-logger@0.1.1",
    "creationix/weblit-static@0.3.1",
    "creationix/weblit-websocket@0.2.3",
  },
  files = {
    "package.lua",
    "init.lua",
  },
  description = "This Weblit metapackage brings in all the official Weblit modules.",
  tags = {"weblit", "meta"},
  license = "MIT",
  author = { name = "Tim Caswell" },
  homepage = "https://github.com/creationix/weblit",
}
