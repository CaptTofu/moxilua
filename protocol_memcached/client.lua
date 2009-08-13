-- All the parts required for memcached client...
--
require('protocol_memcached/protocol_binary')
require('protocol_memcached/protocol_binary_prep')
require('protocol_memcached/protocol_binary_pack')

require('protocol_memcached/client_binary')
require('protocol_memcached/client_ascii')

if _G.sock_recv == nil and
   _G.sock_send == nil and
   _G.sock_send_recv == nil then
  -- Default implementation is blocking LuaSocket implementation.
  --
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
end
