exports.name = "creationix/weblit-app"
exports.version = "0.2.0"
exports.dependencies = {
  'creationix/coro-wrapper@1.0.0',
  'creationix/coro-tcp@1.0.5',
  'luvit/http-codec@1.0.0',
}
--[[
Web App Framework

Middleware Contract:

function middleware(req, res, go)
  req.method
  req.path
  req.params
  req.headers
  req.version
  req.keepAlive
  req.body

  res.code
  res.headers
  res.body

  go() - Run next in chain, can tail call or wait for return and do more

headers is a table/list with numerical headers.  But you can also read and
write headers using string keys, it will do case-insensitive compare for you.

body can be a string or a stream.  A stream is nothing more than a function
you can call repeatedly to get new values.  Returns nil when done.

server
  .bind({
    host = "0.0.0.0",
    port = 8080
  })
  .bind({
    host = "0.0.0.0",
    port = 8443,
    tls = {
      cert = certString,
      key = keyString,
    }
  })
  .route({
    method = "GET",
    host = "^creationix.com",
    path = "/:path:"
  }, middleware)
  .use(middleware)
  .start()
]]

local createServer = require('coro-tcp').createServer
local wrapper = require('coro-wrapper')
local readWrap, writeWrap = wrapper.reader, wrapper.writer
local httpCodec = require('http-codec')
local tlsWrap = require('coro-tls').wrap

local server = {}
local handlers = {}
local bindings = {}

-- Provide a nice case insensitive interface to headers.
local headerMeta = {
  __index = function (list, name)
    if type(name) ~= "string" then
      return rawget(list, name)
    end
    name = name:lower()
    for i = 1, #list do
      local key, value = unpack(list[i])
      if key:lower() == name then return value end
    end
  end,
  __newindex = function (list, name, value)
    if type(name) ~= "string" then
      return rawset(list, name, value)
    end
    local lowerName = name:lower()
    for i = 1, #list do
      local key = list[i][1]
      if key:lower() == lowerName then
        if value == nil then
          table.remove(list, i)
        else
          list[i] = {name, tostring(value)}
        end
        return
      end
    end
    if value == nil then return end
    rawset(list, #list + 1, {name, tostring(value)})
  end,
}

local function handleRequest(head, input, socket)
  local req = {
    socket = socket,
    method = head.method,
    path = head.path,
    headers = setmetatable({}, headerMeta),
    version = head.version,
    keepAlive = head.keepAlive,
    body = input
  }
  for i = 1, #head do
    req.headers[i] = head[i]
  end

  local res = {
    code = 404,
    headers = setmetatable({}, headerMeta),
    body = "Not Found\n",
  }

  local function run(i)
    local success, err = pcall(function ()
      i = i or 1
      local go = i < #handlers
        and function ()
          return run(i + 1)
        end
        or function () end
      return handlers[i](req, res, go)
    end)
    if not success then
      res.code = 500
      res.headers = setmetatable({}, headerMeta)
      res.body = err
      print(err)
    end
  end
  run(1)

  local out = {
    code = res.code,
    keepAlive = res.keepAlive,
  }
  for i = 1, #res.headers do
    out[i] = res.headers[i]
  end
  return out, res.body, res.upgrade
end

local function handleConnection(rawRead, rawWrite, socket)

  -- Speak in HTTP events
  local read, updateDecoder = readWrap(rawRead, httpCodec.decoder())
  local write, updateEncoder = writeWrap(rawWrite, httpCodec.encoder())

  for head in read do
    local parts = {}
    for chunk in read do
      if #chunk > 0 then
        parts[#parts + 1] = chunk
      else
        break
      end
    end
    local res, body, upgrade = handleRequest(head, #parts > 0 and table.concat(parts) or nil, socket)
    write(res)
    if upgrade then
      return upgrade(read, write, updateDecoder, updateEncoder, socket)
    end
    write(body)
    if not (res.keepAlive and head.keepAlive) then
      break
    end
  end
  write()

end

function server.bind(options)
  bindings[#bindings + 1] = options
  return server
end

function server.use(handler)
  handlers[#handlers + 1] = handler
  return server
end


function server.start()
  for i = 1, #bindings do
    local options = bindings[i]
    if not options.port then
      options.port = options.tls and 443 or 80
    end
    createServer(options.host, options.port, function (rawRead, rawWrite, socket)
      local tls = options.tls
      if tls then
        rawRead, rawWrite = tlsWrap(rawRead, rawWrite, {
          server = true,
          key = tls.key,
          cert = tls.cert
        })
      end
      return handleConnection(rawRead, rawWrite, socket)
    end)
    print("HTTP server listening at http" .. (options.tls and "s" or "") .. "://" .. options.host .. (options.port == (options.tls and 443 or 80) and "" or ":" .. options.port) .. "/")
  end
  return server
end

return server
