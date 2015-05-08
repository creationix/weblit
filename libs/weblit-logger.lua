exports.name = "creationix/weblit-logger"
exports.version = "0.1.1-1"
exports.description = "The logger middleware for Weblit logs basic request and response information."
exports.tags = {"weblit", "middleware", "logger"}
exports.license = "MIT"
exports.author = { name = "Tim Caswell" }
exports.homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-logger.lua"

return function (req, res, go)
  -- Skip this layer for clients who don't send User-Agent headers.
  local userAgent = req.headers["user-agent"]
  if not userAgent then return go() end
  -- Run all inner layers first.
  go()
  -- And then log after everything is done
  print(string.format("%s %s %s %s", req.method,  req.path, userAgent, res.code))
end
