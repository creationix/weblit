return function(secret)
  return function (req, res, go)
    local cookies = {}
    for i = 1, #req.headers do
      local key, value = unpack(req.headers[i])
      if key:lower() == "cookie" then
        for k, v in value:gmatch("([^ ;=]+)=([^;=]+)") do
          cookies[k] = v
        end
      end
    end
    req.cookies = cookies
    function res.setCookie(key, value, props)
      cookies[key] = value
      local cookie = key .. "=" .. value
      if type(props) == 'table' then
        for k, v in pairs(props) do
          cookie = cookie .. "; " .. k .. '=' .. v
        end
      end
      res.headers[#res.headers + 1] = {"Set-Cookie", cookie}
    end
    function res.clearCookie(key, props)
      -- set the cookie blank
      local cookie = key .. "=null"
      local props = props or {}
      props.Expires = "Thu, 01 Jan 1970 00:00:00 GMT"
      for k, v in pairs(props) do
        cookie = cookie .. "; " .. k .. '=' .. v
      end
      res.headers[#res.headers + 1] = {"Set-Cookie", cookie}
    end
    return go()
  end
end