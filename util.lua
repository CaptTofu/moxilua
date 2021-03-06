-- Define the sock_send/recv functions to use asynchronous actor sockets.
--
if _G.sock_recv == nil and
   _G.sock_send == nil and
   _G.sock_send_recv == nil and
   _G.asock then
  function sock_recv(skt, pattern)
    return asock.recv(apo.self_address(), skt, pattern)
  end

  function sock_send(skt, data, from, to)
    return asock.send(apo.self_address(), skt, data, from, to)
  end

  function asock_send_recv(self_addr, skt, msg, recv_callback, pattern)
    local ok, err = asock.send(self_addr, skt, msg)
    if not ok then
      return ok, err
    end

    local rv, err = asock.recv(self_addr, skt, pattern or "*l")
    if rv and recv_callback then
      recv_callback(rv)
    end

    return rv, err
  end

  function sock_send_recv(skt, data, recv_callback, pattern)
    return asock_send_recv(apo.self_address(),
                           skt, data, recv_callback, pattern)
  end
end

----------------------------------------

function upstream_accept(self_addr, server_skt, sess_actor, env)
  local session_handler = function(upstream_skt)
    upstream_skt:settimeout(0)

    apo.spawn(sess_actor, env, upstream_skt)
  end

  asock.loop_accept(self_addr, server_skt, session_handler)
end

----------------------------------------

-- Parses "host:port" string.
--
function host_port(str, default_port)
  local host = string.match(str, "//([^:/]+)") or
               string.match(str, "^([^:/]+)")
  if not host then
    return nil
  end

  local port = string.match(str, ":(%d+)")
  if port then
    port = tonumber(port)
  else
    port = default_port
  end

  return host, port
end

-- Create a client connection to a "host:port" location.
--
function connect(location)
  local host, port = host_port(location, 11211)
  if not host then
    return nil
  end

  local sock, err = socket.connect(host, port)
  if not sock then
    return nil, nil, nil, err
  end

  sock:settimeout(0)

  return host, port, sock, nil
end

-- Helper function to close connections, like...
--
--   c1, c2, c3 = close(c1, c2, c3)
--
local function close(...)
  for i, skt in ipairs(arg) do
    skt:close()
  end
  return nil
end

-- Groups items in itr by the key returned by key_func(itr).
--
function group_by(arr, key_func)
  local groups = {}
  for i = 1, #arr do
    local x = arr[i]
    local k = assert(key_func(x))
    local g = groups[k]
    if g then
      table.insert(g, x)
    else
      groups[k] = { x }
    end
  end
  return groups
end

-- Returns an iterator function for an array.
--
function array_iter(arr, start, step)
  if not start then
    start = 1
  end
  if not step then
    step = 1
  end
  local next = start
  return function()
           if not arr then
             return nil
           end
           local v = arr[next]
           next = next + step
           return v
         end
end

-- Returns an array from an iterator function.
--
function iter_array(itr)
  local a = {}
  for v in itr do
    a[#a + 1] = v
  end
  return a
end

------------------------------------------------------

-- Run all functions that have a "TEST_" prefix.
--
function TESTALL()
  for k, v in pairs(_G) do
    if string.match(k, "^TEST_") then
      print("- " .. k)
      v()
    end
  end
  print("TESTALL - done")
end

function TEST_array_iter()
  a = {1,2,3,4,5,6}
  x = array_iter(a)
  for i = 1, #a do
    assert(a[i] == x())
  end
  assert(not x())
  assert(not x())
  x = array_iter(a, 4, 1)
  for i = 4, #a do
    assert(a[i] == x())
  end
  assert(not x())
  assert(not x())
  assert(iter_array(array_iter({'a'}))[1] == 'a')
  assert(iter_array(array_iter({'a'}))[2] == nil)
end

function TEST_host_port()
  h, p = host_port("127.0.0.1:11211")
  assert(h == "127.0.0.1")
  assert(p == 11211)
  h, p = host_port("memcached://127.0.0.1:11211")
  assert(h == "127.0.0.1")
  assert(p == 11211)
  h, p = host_port("memcached://127.0.0.1", 443322)
  assert(h == "127.0.0.1")
  assert(p == 443322)
  h, p = host_port("memcached://127.0.0.1/foo", 443322)
  assert(h == "127.0.0.1")
  assert(p == 443322)
end

function TEST_group_by()
  gb = group_by({1, 2, 2, 3, 3, 3},
                function(x) return x end)
  for k, v in pairs(gb) do
    -- print(k, #v, unpack(v))
    assert(k == #v)
  end
end

