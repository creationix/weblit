--[[lit-meta
  name = "creationix/weblit-force-https"
  version = "2.0.1"
  description = "Redirects http request to https."
  tags = {"weblit", "middleware", "https"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-force-https.lua"
]]

return function (req, res, go)
  if req.socket.tls then return go() end
  res.code = 301
  res.headers["Location"] = "https://" .. req.headers.Host .. req.path
  res.body = "Redirecting to HTTPS...\n"
end
