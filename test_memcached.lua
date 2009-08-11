socket = require('socket')
apo    = require('actor_post_office')
asock  = require('actor_socket')

require 'util'

p = print

function printa(a)
  for i, v in ipairs(a) do
    p(i, v)
  end
end

pa = printa

------------------------------------------

sock_recv = function(skt, pattern)
  return skt:receive(pattern or "*l")
end

sock_send = function(skt, data, from, to)
  return skt:send(data, from, to)
end

sock_send_recv = function(skt, data, recv_callback)
  local ok = sock_send(skt, data)
  if not ok then
    return nil
  end

  local rv = sock_recv(skt)
  if rv and recv_callback then
    recv_callback(rv)
  end

  return rv
end

require('client_ascii')

------------------------------------------

term = { 'END', 'OK', 'STORED', 'ERROR' }
for i, v in ipairs(term) do
  term[v] = true
end

function read_end(c)
  local r = {}
  repeat
    local x, err = c:receive()
    p("received", x, err)
    table.insert(r, x)
  until err or term[r[#r]]
  return r
end

------------------------------------------

got_last = {}
function fresh()
  got_last = {}
end

function got(...)
  got_last = arg
  pa(arg)
end

function expected(...)
  assert(#got_last == #arg)
  for i = 1, #arg do
    if not string.find(got_last[i], "^" .. arg[i]) then
      p("expected", arg[i], "got", got_last[i])
      assert(false)
    end
  end
end

------------------------------------------

location = arg[1] or '127.0.0.1:11211'

host, port, c = connect(location)
c:settimeout(nil)

------------------------------------------

p("connected", host, port, c)

fresh()
assert(client_ascii.flush_all(c, got))
expected("OK")

fresh()
assert(client_ascii.get(c, got, {"a"}))
expected()

fresh()
assert(client_ascii.set(c, got, {"a", "0", "0", "5"}, "hello"))
expected("STORED")

fresh()
assert(client_ascii.get(c, got, {"a"}))
expected("VALUE a",
         "hello")

p("done!")
