require('weblit-websocket')
require('weblit-app')
  .bind {host = "0.0.0.0", port = 8080 }

 -- Set an outer middleware for logging requests and responses
  .use(require('weblit-logger'))

  -- This adds missing headers, and tries to do automatic cleanup.
  .use(require('weblit-auto-headers'))


  .websocket({
    path = "/",
    protocol = "test"
  }, function (req, read, write)
    print("New client")
    for message in read do
      message.mask = nil
      write(message)
    end
    write()
    print("Client left")
  end)--

  -- Bind the ports, start the server and begin listening for and accepting connections.
  .start()
