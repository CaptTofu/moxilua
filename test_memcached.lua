require 'socket'
require 'util'

p = print

term = { 'END', 'OK', 'STORED' }
for i, v in ipairs(term) do
  term[v] = true
end

function read_end(c)
  local r = {}
  repeat
    local x, err = c:receive()
    table.insert(r, x)
  until err ~= nil or term[r[#r]]
  return r
end

function printa(a)
  for i, v in ipairs(a) do
    print(i, v)
  end
end

host, port, c = connect('127.0.0.1:11211')

c:send("get a\r\n")
printa(read_end(c))

c:send("set a 0 0 5\r\n")
c:send("hello\r\n")
printa(read_end(c))

