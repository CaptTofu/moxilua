socket = require('socket')

apo   = require('actor_post_office')
asock = require('actor_socket')

require('util')

require('spec_map')
require('spec_proxy')

print("start")

----------------------------------------

function upstream_session(self_addr, upstream_skt, specs, go_data)
print("us started", upstream_skt)
  local cmdline = true
  while cmdline do
print("us started", upstream_skt, "asoc.recv'ing")
    cmdline = asock.recv(self_addr, upstream_skt, "*l")
print("us started", upstream_skt, "asoc.recv'ed", cmdline)
    if cmdline then
      local itr = string.gfind(cmdline, "%S+")
      local cmd = itr()
      if cmd then
print("us started", upstream_skt, "asoc.recv'ed", cmdline, cmd)
        local spec = specs[cmd]
print("us started", upstream_skt, "asoc.recv'ed", cmdline, cmd, spec)
        if spec then
          if not spec.go(go_data, self_addr, upstream_skt,
                         cmdline, cmd, itr) then
            cmdline = nil
          end
        else
          asock.send(self_addr, upstream_skt, "ERROR\r\n")
        end
      end
    end
  end

print("us closing", upstream_skt)
  upstream_skt:close()
end

function upstream_accept(self_addr, server_skt, specs, go_data)
  asock.loop_accept(self_addr, server_skt, function(upstream_skt)
    upstream_skt:settimeout(0)
    apo.spawn(upstream_session, upstream_skt, specs, go_data)
print("ua spawned us", upstream_skt)
  end)
end

----------------------------------------

host = "127.0.0.1"

server = socket.bind(host, 11211)
apo.spawn(upstream_accept, server,
          spec_map, {})

apo.loop_until_empty()

server = socket.bind(host, 11222)
apo.spawn(upstream_accept, server,
          spec_proxy, create_pool({"127.0.0.1:11211"}))

apo.loop_until_empty()

print("loop")

while true do
  apo.loop_until_empty()
  asock.step()
end

print("done")

