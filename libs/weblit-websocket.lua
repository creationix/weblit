exports.name = "creationix/weblit-websocket"
exports.version = "0.1.0"
exports.dependencies = {
  "creationix/websocket-codec@1.0.1"
}

local websocketCodec = require('websocket-codec')

local server = require('weblit-app')

function server.websocket(options, handler)
  server.use(function (req, res, go)
    -- Websocket connections must be GET requests
    -- with 'Upgrade: websocket'
    -- and 'Connection: Upgrade' headers
    local headers = req.headers
    local connection = headers.connection
    local upgrade = headers.upgrade
    if not (
      req.method == "GET" and
      upgrade and upgrade:lower() == "websocket" and
      connection and connection:lower() == "upgrade"
    ) then
      return go()
    end

    -- If there is a sub-protocol specified, filter on it.
    local protocol = options.protocol
    if protocol then
      local list = headers["sec-websocket-protocol"]
      local foundProtocol
      if list then
        for item in list:gmatch("[^, ]+") do
          if item == protocol then
            foundProtocol = true
            break
          end
        end
      end
      if not foundProtocol then
        return go()
      end
    end

    -- Make sure it's a new client speaking v13 of the protocol
    assert(tonumber(headers["sec-websocket-version"]) >= 13, "only websocket protocol v13 supported")

    -- Get the security key
    local key = assert(headers["sec-websocket-key"], "websocket security required")

    res.code = 101
    headers = res.headers
    headers.Upgrade = "websocket"
    headers.Connection = "Upgrade"
    headers["Sec-WebSocket-Accept"] = websocketCodec.acceptKey(key)
    if protocol then
      headers["Sec-WebSocket-Protocol"] = protocol
    end
    function res.upgrade(read, write, updateDecoder, updateEncoder, socket)
      updateDecoder(websocketCodec.decode)
      updateEncoder(websocketCodec.encode)
      return handler(read, write, socket)
    end
  end)
  return server
end

return server
