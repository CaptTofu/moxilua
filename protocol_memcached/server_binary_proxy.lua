-- Need a noreply version of client_binary api.
-- Also, need to handle opaque's right.
--
memcached_server_binary_proxy = {}

local msbp = memcached_server_binary_proxy
local mpb  = memcached_protocol_binary
local pack = mpb.pack

local SUCCESS = mpb.response_stats.SUCCESS

msbp[mpb.command.GET] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.SET] =
  function(pool, skt, req, key, ext, data)
    local downstream_addr = pool.choose(key)
    if downstream_addr then
      apo.send(downstream_addr, apo.self_address(),
               skt, mpb.command.SET, {req, key, ext}, data)
      apo.recv()
      return true
    end

    return false -- TODO: send err response.
  end

msbp[mpb.command.ADD] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.REPLACE] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.DELETE] =
  function(pool, skt, req, key, ext, data)
    local downstream_addr = pool.choose(key)
    if downstream_addr then
      apo.send(downstream_addr, apo.self_address(),
               skt, mpb.command.DELETE, {req, key, ext}, data)
      apo.recv()
      return true
    end

    return false -- TODO: send err response.
  end

msbp[mpb.command.INCREMENT] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.DECREMENT] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.QUIT] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.FLUSH] =
  function(pool, skt, req, key, ext, data)
    local n = 0
    pool.each(
      function(downstream_addr)
        apo.send(downstream_addr, apo.self_address(),
                 false, mpb.command.FLUSH, {req, key, ext}, data)
        n = n + 1
      end)

    for i = 1, n do
      apo.recv()
    end

    local res =
      pack.create_response_simple(mpb.command.FLUSH, SUCCESS,
                                  pack.opaque(req, 'request'))
    return sock_send(skt, res)
  end

msbp[mpb.command.GETQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.NOOP] =
  function(pool, skt, req, key, ext, data)
    local function skt_send(head, body)
      if pack.opcode(head, 'response') == mpb.command.NOOP then
        return
      end

      local key  = body[1]
      local ext  = body[2]
      local data = body[3]

      local msg = head .. (ext or "") .. (key or "") .. (data or "")

      return sock_send(skt, msg)
    end

    local n = 0
    pool.each(
      function(downstream_addr)
        apo.send(downstream_addr, apo.self_address(),
                 false, mpb.command.NOOP, {req, key, ext}, data,
                 skt_send)
        n = n + 1
      end)

    for i = 1, n do
      apo.recv()
    end

    local res =
      pack.create_response_simple(mpb.command.NOOP, SUCCESS,
                                  pack.opaque(req, 'request'))
    return sock_send(skt, res)
  end

msbp[mpb.command.VERSION] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.GETK] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.GETKQ] =
  function(pool, skt, req, key, ext, data)
    local downstream_addr = pool.choose(key)
    if downstream_addr then
      apo.send(downstream_addr, apo.self_address(),
               skt, mpb.command.GETKQ, {req, key, ext}, data)
      apo.recv()
    end
    return true
  end

msbp[mpb.command.APPEND] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.PREPEND] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.STAT] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.SETQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.ADDQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.REPLACEQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.DELETEQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.INCREMENTQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.DECREMENTQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.QUITQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.FLUSHQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.APPENDQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.PREPENDQ] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.SASL_LIST_MECHS] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.SASL_AUTH] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.SASL_STEP] =
  function(pool, skt, req, key, ext, data)
  end

msbp[mpb.command.BUCKET] =
  function(pool, skt, req, key, ext, data)
  end

