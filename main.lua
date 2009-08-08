apo    = require('actor_post_office')
socket = require('socket')
copas  = require('copas')

require('util')

require('spec_map')
require('spec_proxy')

print("start")

----------------------------------------

function upstream_sess(specs, go_data)
  return function(skt_in)
    local self_addr = apo.register(coroutine.running())

    skt = copas.wrap(skt_in)

    local cmdline = true
    while cmdline do
      cmdline = skt:receive()
      if cmdline then
        local itr = string.gfind(cmdline, "%S+")
        local cmd = itr()
        if cmd then
          local spec = specs[cmd]
          if spec then
            if not spec.go(go_data, self_addr, skt, cmdline, cmd, itr) then
              cmdline = nil
            end
          else
            skt:send("ERROR\r\n")
          end
        end
      end
    end

    skt_in:close()

    apo.unregister(self_addr)
  end
end

----------------------------------------

host = "127.0.0.1"

server = socket.bind(host, 11211)
copas.addserver(server, upstream_sess(spec_map, {}))

server = socket.bind(host, 11222)
copas.addserver(server, upstream_sess(spec_proxy, {}))

print("loop")

while true do
  apo.loop_until_empty()
  copas.step()
end

print("done")

