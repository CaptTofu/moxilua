socket = require('socket')

apo   = require('actor_post_office')
asock = require('actor_socket')

require('util')

require('protocol_memcached/client_ascii')
require('protocol_memcached/server_ascii_dict')
require('protocol_memcached/server_ascii_proxy')

require('pool')

print("start")

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
          if not spec(go_data, upstream_skt, itr) then
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
          server_ascii_dict, { tbl = {} })

server = socket.bind(host, 11333)
apo.spawn(upstream_accept, server,
          server_ascii_proxy,
          create_pool({ "127.0.0.1:11311" }))

print("loop")

while true do
  apo.loop_until_empty()
  asock.step()
end

print("done")

