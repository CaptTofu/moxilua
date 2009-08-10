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

  return host, port, sock, nil
end

-- Groups items in itr by the key returned by key_func(itr).
--
function group_by(itr, key_func)
  local groups = {}
  for x in itr do
    local key = key_func(x)
    local group = groups[key]
    if not group then
      groups[key] = { x }
    else
      table.insert(group, x)
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
    assert(k == #v)
    print(k, #v, unpack(v))
  end
end

