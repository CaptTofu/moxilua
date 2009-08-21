local dict_update_map = {
  set =
    function(dict, key, flag, expire, data)
      dict.tbl[key] = data
      return true, "STORED"
    end,
  add =
    function(dict, key, flag, expire, data)
      if dict.tbl[key] then
        return false, "NOT_STORED"
      end
      dict.tbl[key] = data
      return true, "STORED"
    end,
  replace =
    function(dict, key, flag, expire, data)
      if not dict.tbl[key] then
        return false, "NOT_STORED"
      end
      dict.tbl[key] = data
      return true, "STORED"
    end,
  append =
    function(dict, key, flag, expire, data)
      dict.tbl[key] = (dict.tbl[key] or "") .. data
      return true, "STORED"
    end,
  prepend =
    function(dict, key, flag, expire, data)
      dict.tbl[key] = data .. (dict.tbl[key] or "")
      return true, "STORED"
    end
}

---------------------------------------------------

local function dict_update(dict, skt, cmd, arr)
  local key    = arr[1]
  local flag   = arr[2]
  local expire = arr[3]
  local size   = arr[4]

  if key and flag and expire and size then
    size = tonumber(size)
    if size >= 0 then
      local data, err = sock_recv(skt, tonumber(size) + 2) -- 2 for CR/NL.
      if not data then
        return data, err
      end

      local ok, msg =
        dict_update_map[cmd](dict, key, flag, expire,
                             string.sub(data, 1, -3))

      return sock_send(skt, msg .. "\r\n")
    end
  end

  return sock_send(skt, "ERROR\r\n")
end

---------------------------------------------------

memcached_server_ascii_dict = {
  get =
    function(dict, skt, cmd, arr)
      for i = 1, #arr do
        local key = arr[i]

        data = dict.tbl[key]
        if data then
          local ok, err = sock_send(skt, "VALUE " ..
                                         key .. "\r\n" ..
                                         data .. "\r\n")
          if not ok then
            return ok, err
          end
        end
      end
      return sock_send(skt, "END\r\n")
    end,

  set     = dict_update,
  add     = dict_update,
  replace = dict_update,
  append  = dict_update,
  prepend = dict_update,

  delete =
    function(dict, skt, cmd, arr)
      local key = arr[1]
      if key then
        if dict.tbl[key] then
          dict.tbl[key] = nil
          return sock_send(skt, "DELETED\r\n")
        else
          return sock_send(skt, "NOT_FOUND\r\n")
        end
      end
      return sock_send(skt, "ERROR\r\n")
    end,

  flush_all =
    function(dict, skt, cmd, arr)
      dict.tbl = {}
      return sock_send(skt, "OK\r\n")
    end,

  quit =
    function(dict, skt, cmd, arr)
      return false
    end
}

