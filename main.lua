socket = require('socket')

apo   = require('actor_post_office')
asock = require('actor_socket')

require('util')

require('spec_map')
require('spec_client')
require('spec_proxy')

require('downstream')

print("start")

----------------------------------------

recv = apo.recv
send = apo.send

function sock_recv(skt, pattern)
  return asock.recv(apo.self_address(), skt, pattern)
end

function sock_send(skt, data, from, to)
  return asock.send(apo.self_address(), skt, data, from, to)
end

function sock_send_recv(skt, data, recv_callback)
  return asock.send_recv(apo.self_address(), skt, data, recv_callback)
end

----------------------------------------

function upstream_session(self_addr, upstream_skt, specs, go_data)
  local cmdline = true
  while cmdline do
    cmdline = asock.recv(self_addr, upstream_skt, "*l")
    if cmdline then
      local itr = string.gfind(cmdline, "%S+")
      local cmd = itr()
      if cmd then
        local spec = specs[cmd]
        if spec then
          if not spec(go_data, self_addr, upstream_skt,
                      cmdline, cmd, itr) then
            cmdline = nil
          end
        else
          asock.send(self_addr, upstream_skt, "ERROR\r\n")
        end
      end
    end
  end

  upstream_skt:close()
end

function upstream_accept(self_addr, server_skt, specs, go_data)
  asock.loop_accept(self_addr, server_skt, function(upstream_skt)
    upstream_skt:settimeout(0)
    apo.spawn(upstream_session, upstream_skt, specs, go_data)
  end)
end

----------------------------------------

host = "127.0.0.1"

server = socket.bind(host, 11311)
apo.spawn(upstream_accept, server,
          spec_map, {})

server = socket.bind(host, 11333)
apo.spawn(upstream_accept, server,
          spec_proxy,
          create_downstream_pool({ "127.0.0.1:11311" }))

print("loop")

while true do
  apo.loop_until_empty()
  asock.step()
end

print("done")

