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

