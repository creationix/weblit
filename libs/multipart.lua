--[[

Copyright 2015 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]
local lpeg = require'lpeg'

local P,R,S,V = lpeg.P,lpeg.R,lpeg.S,lpeg.V
local    C,     Cb,     Cf,    Cg,      Ct,     Cmt = 
    lpeg.C,lpeg.Cb,lpeg.Cf,lpeg.Cg,lpeg.Ct,lpeg.Cmt
local alpha  = R('az')+R('AZ')

local line       = P"--"
local crlf       = P"\r"^-1 * P"\n"
local name_value = Cg(C(alpha^1) * '=' * P'"'^-1 * C( (1-P'"'-crlf)^0 ) * P'"'^-1) - crlf
local name_      = alpha^1 * (P'-'^0    * alpha)^1
local subtype    = alpha^1 * (S('/-')^0 * alpha)^1

local header     = Ct(C(name_) * ': ' * C(subtype) * Cf(Ct"" * (S(',;') * ' ' * name_value)^0,rawset) )

local headers    = Ct( header * (crlf*header)^0 )

local build = function(boundary)  
  local _, _, bound = string.find(boundary,'boundary=(.+)')
  if (bound) then
    boundary = P(bound)
  else
    boundary = P(boundary)
  end
  
  local node        = Ct(line*boundary*crlf*headers*crlf*crlf*C( (P(1)-crlf*line*boundary)^0 ))
  local nodes       = Ct(node * (crlf*node)^0 * crlf * line*boundary*line)
  return nodes
end

local basic_parse = function(multipart, boundary)
  local nodes = build(boundary)
  return lpeg.match(nodes,multipart)
end


local io = require'enhance.io'
local echo = function(s) print(s) end

---[[
local parse
parse=function(body, boundary, complex)
  local basic = basic_parse(body,boundary)
  if not basic then
    print(boundary)
    print(body)
  end
  local ret = {}
  for i=1,#basic do
    local part = basic[i]
    local headers,value = part[1],part[2]
    if(string.lower(headers[1][1])=='content-disposition' 
      and headers[1][2]=='form-data') then
      --form-data
      if (headers[1][3].filename) then
          --handle fileupload
          local file = {filename=headers[1][3].filename}
          file[1] = value
          for j=2,#headers do
            file[headers[j][1]] = headers[j][2]
          end
          ret[headers[1][3].name] = file
      else
        if #headers==1 then
          --simple key-value pair        
          ret[headers[1][3].name] = value
        else
          local t = {}
          ret[headers[1][3].name] = t
          if(string.lower(headers[2][1])=='content-type'
            and string.match(headers[2][2],'^multipart')) then
            --multipart sub
            io.print_r(headers)
            ret[headers[1][3].name] = assert(parse(value,headers[2][3].boundary))
            io.print_r(headers)            
          else
            ret[headers[1][3].name] = value
          end
        end
      end
    else
    end
  end
  return ret
end
--]]

exports.parse = parse
return exports

--[===[
local test = {
--[==[
  ['Content-type: multipart/form-data, boundary=AaB03x'] = [[
--AaB03x
content-disposition: form-data; name="field1"

Joe Blow
--AaB03x
content-disposition: form-data; name="pics"
Content-type: multipart/mixed, boundary=BbC04y

--BbC04y
Content-disposition: attachment; filename="file1.txt"
Content-Type: text/plain

... contents of file1.txt ...
--BbC04y
Content-disposition: attachment; filename="file2.gif"
Content-type: image/gif
Content-Transfer-Encoding: binary

...contents of file2.gif...
--BbC04y--
--AaB03x--
]],
--]==]
---[==[
['Content-type: multipart/form-data, boundary=AaB03y'] = [[
--AaB03y
content-disposition: form-data; name="field1"

Joe Blow
--AaB03y
content-disposition: form-data; name="pics"; filename="file1.txt"
Content-Type: text/plain

 ... contents of file1.txt ...
--AaB03y--
]],
--]==]
---[==[
['Content-type: multipart/form-data, boundary=AaB03z'] = [[
--AaB03z
content-disposition: form-data; name="field1"
content-type: text/plain; charset=windows-1250
content-transfer-encoding: quoted-printable


Joe owes =80100.
--AaB03z--]],
--]==]
---[==[
['multipart/form-data; boundary=----WebKitFormBoundary6bHnnUFIFpNjRCNi'] = [[
------WebKitFormBoundary6bHnnUFIFpNjRCNi
Content-Disposition: form-data; name="field1"


------WebKitFormBoundary6bHnnUFIFpNjRCNi
Content-Disposition: form-data; name="file"; filename=""
Content-Type: application/octet-stream


------WebKitFormBoundary6bHnnUFIFpNjRCNi--
]]
--]==]
}

for k,v in pairs(test) do
  --io.print_r(basic_parse(v,k))
  io.print_r(parse(v,k))
end
--]===]
