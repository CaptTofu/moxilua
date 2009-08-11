recv = apo.recv
send = apo.send

function sock_recv(skt, pattern)
  return asock.recv(apo.self_address(), skt, pattern)
end

function sock_send(skt, data, from, to)
  return asock.send(apo.self_address(), skt, data, from, to)
end

function send_recv(self_addr, skt, msg, recv_callback)
  local ok = asock.send(self_addr, skt, msg)
  if not ok then
    return nil
  end

  local rv = asock.recv(self_addr, skt)
  if rv and recv_callback then
    recv_callback(rv)
  end

  return rv
end

function sock_send_recv(skt, data, recv_callback)
  return send_recv(apo.self_address(), skt, data, recv_callback)
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
function group_by(itr, key_func)
  local groups = {}
  for x in itr do
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
  local next = 1
  return function()
           if not arr then
             return nil
           end
           local v = arr[next]
           next = next + step
           return v
         end
end

-- Returns a string of array elements joined with a
-- separator string (defaults to " ").  An optional
-- fun parameter is a function to call on each array item.
--
function array_join(a, sep, fun)
  if a and #a > 0 then
    fun = fun or tostring
    sep = sep or " "

    local r = fun(a[1])
    for i = 2, #a do
      r = r .. sep .. fun(a[i])
    end

    return r
  end

  return ""
end

------------------------------------------------------

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
  gb = group_by(array_iter({1, 2, 2, 3, 3, 3}),
                function(x) return x end)
  for k, v in pairs(gb) do
    print(k, #v, unpack(v))
    assert(k == #v)
  end
end

function TEST_array_join()
  print(array_join({1,2,3}))
  assert(array_join({1,2,3}) == "1 2 3")

  print(array_join({1}))
  assert(array_join({1}) == "1")

  print(array_join({}))
  assert(array_join({}) == "")
end
