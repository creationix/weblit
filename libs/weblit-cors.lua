--[[lit-meta
  name = "creationix/weblit-cors"
  version = "2.0.0"
  description = "The logger middleware To add uncionditional CORS headers."
  tags = {"weblit", "middleware", "cors"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-cors.lua"
]]

return function (_, res, go)
  go()
  res.headers["Access-Control-Allow-Origin"] = "*"
  res.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"
end
