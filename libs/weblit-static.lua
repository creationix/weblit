--[[lit-meta
  name = "creationix/weblit-static"
  version = "2.2.2"
  dependencies = {
    "creationix/mime@2.0.0",
    "creationix/coro-fs@2.2.2",
    "luvit/json@2.5.2",
    "creationix/sha1@1.0.0",
  }
  description = "A weblit middleware for serving static files from disk or bundle."
  tags = {"weblit", "middleware", "static"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-auto-headers.lua"
]]

local getType = require("mime").getType
local jsonStringify = require('json').stringify
local sha1 = require('sha1')

return function (rootPath)
  local fs
  local i, j = rootPath:find("^bundle:")
  if i then
    local pathJoin = require('luvi').path.join
    local prefix = rootPath:sub(j + 1)
    if prefix:byte(1) == 47 then
      prefix = prefix:sub(2)
    end
    local bundle = require('luvi').bundle
    fs = {}
    -- bundle.stat
    -- bundle.readdir
    -- bundle.readfile
    function fs.stat(path)
      return bundle.stat(pathJoin(prefix, path))
    end
    function fs.scandir(path)
      local dir = bundle.readdir(pathJoin(prefix, path))
      local offset = 1
      return function ()
        local name = dir[offset]
        if not name then return end
        offset = offset + 1
        local stat = bundle.stat(pathJoin(prefix, path, name))
        stat.name = name
        return stat
      end
    end
    function fs.readFile(path)
      return bundle.readfile(pathJoin(prefix, path))
    end
  else
    fs = require('coro-fs').chroot(rootPath)
  end

  return function (req, res, go)
    if req.method ~= "GET" then return go() end
    local path = (req.params and req.params.path) or req.path
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end
    local stat = fs.stat(path)
    if not stat then return go() end

    local function renderFile()
      local body = assert(fs.readFile(path))
      res.code = 200
      res.headers["Content-Type"] = getType(path)
      res.headers["ETag"] = '"' .. sha1(body) .. '"'
      res.body = body
      return
    end

    local function renderDirectory()
      if req.path:byte(-1) ~= 47 then
        res.code = 301
        res.headers.Location = req.path .. '/'
        return
      end
      local files = {}
      for entry in fs.scandir(path) do
        if entry.name == "index.html" and entry.type == "file" then
          path = (#path > 0 and path .. "/" or "") .. "index.html"
          return renderFile()
        end
        files[#files + 1] = entry
        entry.url = "http://" .. req.headers.host .. req.path .. entry.name
      end
      local body = jsonStringify(files) .. "\n"
      res.code = 200
      res.headers["Content-Type"] = "application/json"
      res.body = body
      return
    end

    if stat.type == "directory" then
      return renderDirectory()
    elseif stat.type == "file" then
      if req.path:byte(-1) == 47 then
        res.code = 301
        res.headers.Location = req.path:match("^(.*[^/])/+$")
        return
      end
      return renderFile()
    end
  end
end
