exports.name = "creationix/weblit-route"
exports.version = "0.1.0"

local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
local function escape(str)
    return str:gsub(quotepattern, "%%%1")
end

local function compileGlob(glob)
  local parts = {"^"}
  for a, b in glob:gmatch("([^*]*)(%**)") do
    if #a > 0 then
      parts[#parts + 1] = escape(a)
    end
    if #b > 0 then
      parts[#parts + 1] = "(.*)"
    end
  end
  parts[#parts + 1] = "$"
  local pattern = table.concat(parts)
  return function (string)
    return string:match(pattern)
  end
end

local function compileRoute(route)
  local parts = {"^"}
  local names = {}
  for a, b, c, d in route:gmatch("([^:]*):([_%a][_%w]*)(:?)([^:]*)") do
    if #a > 0 then
      parts[#parts + 1] = escape(a)
    end
    if #c > 0 then
      parts[#parts + 1] = "(.*)"
    else
      parts[#parts + 1] = "([^/]*)"
    end
    names[#names + 1] = b
    if #d > 0 then
      parts[#parts + 1] = escape(d)
    end
  end
  if #parts == 1 then
    return function (string)
      if string == route then return {} end
    end
  end
  parts[#parts + 1] = "$"
  local pattern = table.concat(parts)
  return function (string)
    local matches = {string:match(pattern)}
    if #matches > 0 then
      local results = {}
      for i = 1, #matches do
        results[i] = matches[i]
        results[names[i]] = matches[i]
      end
      return results
    end
  end
end

local server = require('weblit-app')

function server.route(options, handler)
  local method = options.method
  local path = options.path and compileRoute(options.path)
  local host = options.host and compileGlob(options.host)
  server.use(function (req, res, go)
    if method and req.method ~= method then return go() end
    if host and not (req.headers.host and host(req.headers.host)) then return go() end
    local params
    if path then
      params = path(req.path:match("^[^?#]*"))
      if not params then return go() end
    end
    req.params = params or {}
    return handler(req, res, go)
  end)
  return server
end

return server
