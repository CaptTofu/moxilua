socket = require('socket')

apo   = require('actor_post_office')
asock = require('actor_socket')

require('util')

require('protocol_memcached/client')
require('protocol_memcached/server_ascii')
require('protocol_memcached/server_ascii_dict')
require('protocol_memcached/server_ascii_proxy')
require('protocol_memcached/pool')

print("start")

----------------------------------------

function upstream_accept(self_addr, server_skt,
                         sess_actor, specs, go_data)
  local session_handler = function(upstream_skt)
    upstream_skt:settimeout(0)

    apo.spawn(sess_actor, specs, go_data, upstream_skt)
  end

  asock.loop_accept(self_addr, server_skt, session_handler)
end

----------------------------------------

host = "127.0.0.1"

dict = { tbl = {} }

-- Start ascii server.
server = socket.bind(host, 11311)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_ascii,
          memcached_server_ascii_dict, dict)

-- Start ascii proxy to ascii self.
server = socket.bind(host, 11322)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_ascii,
          memcached_server_ascii_proxy,
          memcached_pool({ "127.0.0.1:11311" }))

print("loop")

while true do
  apo.loop_until_empty()
  asock.step()
end

print("done")

