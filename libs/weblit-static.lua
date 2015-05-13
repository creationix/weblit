exports.name = "creationix/weblit-static"
exports.version = "0.3.1"
exports.dependencies = {
  "creationix/mime@0.1.0",
  "creationix/hybrid-fs@0.1.0",
}
exports.description = "The auto-headers middleware helps Weblit apps implement proper HTTP semantics"
exports.tags = {"weblit", "middleware", "http"}
exports.license = "MIT"
exports.author = { name = "Tim Caswell" }
exports.homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-auto-headers.lua"

local getType = require("mime").getType
local jsonStringify = require('json').stringify

local makeChroot = require('hybrid-fs')

return function (path, options)

  options = options or {}

  local fs = makeChroot(path)

  return function (req, res, go)
    if req.method ~= "GET" then return go() end
    local path = (req.params and req.params.path) or req.path
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end

    local stat = fs.stat(path)
    if not stat then return go() end

    local index_appended = false
    if options.index and stat.type == "directory" then
      local path_with_index = path .. options.index
      local stat_with_index = fs.stat(path_with_index)
      if not stat_with_index then return go() end
      if stat_with_index.type ~= 'file' then return go() end
      path = path_with_index
      stat = stat_with_index
      index_appended = true
    end

    if stat.type == "directory" then
      if req.path:byte(-1) ~= 47 then
        res.code = 301
        res.headers.Location = req.path .. '/'
        return
      end
      local files = {}
      for entry in fs.scandir(path) do
        files[#files + 1] = entry
        entry.url = "http://" .. req.headers.host .. req.path .. entry.name
      end
      local body = jsonStringify(files) .. "\n"
      res.code = 200
      res.headers["Content-Type"] = "application/json"
      res.body = body
      return
    end
    if stat.type == "file" then
      if req.path:byte(-1) == 47 and not index_appended then
        res.code = 301
        res.headers.Location = req.path:match("^(.*[^/])/+$")
        return
      end
      local body = assert(fs.readFile(path))
      res.code = 200
      res.headers["Content-Type"] = getType(path)
      res.body = body
      return
    end
  end
end
