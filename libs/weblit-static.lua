exports.name = "creationix/weblit-static"
exports.version = "0.2.1"
exports.dependencies = {
  "creationix/mime@0.1.0",
  "creationix/coro-fs@1.2.3",
}

local getType = require("mime").getType
local jsonStringify = require('json').stringify
local makeChroot = require('fs').chroot

return function (path)

  local fs = makeChroot(path)

  return function (req, res, go)
    if req.method ~= "GET" then return go() end
    local path = (req.params and req.params.path) or req.path
    if path:byte(1) == 47 then
      path = path:sub(2)
    end
    local stat = fs.stat(path)
    if not stat then return go() end
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
      if req.path:byte(-1) == 47 then
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
