local ffi = require('ffi')
local hd = require('hoedown')

local markdown = [[
# Luvit Blob

This is a blog for luvit related stuffs.
]]

local function markdownToHtml(markdown)
  local flags = hd.HOEDOWN_HTML_ESCAPE
  local renderer = hd.hoedown_html_renderer_new(flags, 0)
  local extensions = bit.bor(
    hd.HOEDOWN_EXT_BLOCK,
    hd.HOEDOWN_EXT_SPAN
  )
  local document = hd.hoedown_document_new(renderer, extensions, 16);
  local html = hd.hoedown_buffer_new(16)
  hd.hoedown_document_render(document, html, markdown, #markdown);
  local string = ffi.string(html.data, html.size)
  hd.hoedown_buffer_free(html)
  hd.hoedown_document_free(document)
  hd.hoedown_html_renderer_free(renderer)
  return string
end

local function renderIndex(req, res)
  res.code = 200
  res.body = markdownToHtml(markdown)
  res["Content-Type"] = "text/html"
end

require('weblit-app')
  .bind {host = "0.0.0.0", port = 8080 }

 -- Set an outer middleware for logging requests and responses
  .use(require('weblit-logger'))

  -- This adds missing headers, and tries to do automatic cleanup.
  .use(require('weblit-auto-headers'))

  -- A caching proxy layer for backends supporting Etags
  .use(require('weblit-etag-cache'))

  --
  .route({
    method = "GET",
    path = "/",
  }, renderIndex)

  -- Bind the ports, start the server and begin listening for and accepting connections.
  .start()
