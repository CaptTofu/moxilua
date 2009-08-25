socket = require('socket')

apo   = require('actor_post_office')
asock = require('actor_socket')

require('util')

require('protocol_memcached/client')
require('protocol_memcached/server')
require('protocol_memcached/server_ascii_dict')
require('protocol_memcached/server_ascii_proxy')
require('protocol_memcached/server_binary_dict')
require('protocol_memcached/server_binary_proxy')
require('protocol_memcached/server_replication')
require('protocol_memcached/pool')

print("start")

----------------------------------------

host = "127.0.0.1"

-- An in-memory dictionary for when we are a memcached server.
-- The extra level of indirection with the sub-dict ("tbl")
-- allows for easy flush_all implementation.
--
dict = { tbl = {} }

---------------

-- Start ascii proxy to memcached.
server = socket.bind(host, 11300)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_ascii, {
            specs = memcached_server_ascii_proxy,
            data =
              memcached_pool({
                { location = "127.0.0.1:11211", kind = "ascii" }
              })
          })

-- Start binary proxy to memcached.
server = socket.bind(host, 11400)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_binary, {
            specs = memcached_server_binary_proxy,
            data =
              memcached_pool({
                { location = "127.0.0.1:11211", kind = "binary" }
              })
          })

---------------

-- Start ascii self server (in-memory dict).
server = socket.bind(host, 11311)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_ascii, {
            specs = memcached_server_ascii_dict,
            data = dict
          })

-- Start binary self server (in-memory dict).
server = socket.bind(host, 11411)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_binary, {
            specs = memcached_server_binary_dict,
            data = dict
          })

---------------

-- Start ascii proxy to ascii self.
server = socket.bind(host, 11322)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_ascii, {
            specs = memcached_server_ascii_proxy,
            data =
              memcached_pool({
                { location = "127.0.0.1:11311", kind = "ascii" }
              })
          })

-- Start binary proxy to binary self.
server = socket.bind(host, 11422)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_binary, {
            specs = memcached_server_binary_proxy,
            data =
              memcached_pool({
                { location = "127.0.0.1:11411", kind = "binary" }
              })
          })

---------------

-- Start ascii proxy to binary memcached.
server = socket.bind(host, 11333)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_ascii, {
            specs = memcached_server_ascii_proxy,
            data =
              memcached_pool({
                { location = "127.0.0.1:11211", kind = "binary" }
              })
          })

-- Start binary proxy to ascii memcached.
server = socket.bind(host, 11433)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_binary, {
            specs = memcached_server_binary_proxy,
            data =
              memcached_pool({
                { location = "127.0.0.1:11211", kind = "ascii" }
              })
          })

---------------

-- Start ascii proxy to binary self.
server = socket.bind(host, 11344)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_ascii, {
            specs = memcached_server_ascii_proxy,
            data =
              memcached_pool({
                { location = "127.0.0.1:11411", kind = "binary" }
              })
          })

-- Start binary proxy to ascii self.
server = socket.bind(host, 11444)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_binary, {
            specs = memcached_server_binary_proxy,
            data =
              memcached_pool({
                { location = "127.0.0.1:11311", kind = "ascii" }
              })
          })

---------------

-- Start replicating ascii proxy to memcached.
server = socket.bind(host, 11500)
apo.spawn(upstream_accept, server,
          upstream_session_memcached_ascii, {
            specs = memcached_server_replication,
            data = {
              memcached_pool({
                { location = "127.0.0.1:11211", kind = "ascii" }
              }),
              memcached_pool({
                { location = "127.0.0.1:11311", kind = "ascii" }
              })
            }
          })

----------------------------------------

print("loop")

while true do
  apo.loop_until_empty()
  asock.step()
end

print("done")

