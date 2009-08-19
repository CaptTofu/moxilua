-- Need a noreply version of client_binary api.
-- Also, need to handle opaque's right.
--
memcached_server_b2b_proxy = {}

local msbp = memcached_server_b2b_proxy
local mpb  = memcached_protocol_binary
local pack = mpb.pack

local SUCCESS = mpb.response_stats.SUCCESS

------------------------------------------------------

-- For binary commands that just do a simple command forward.
--
local function forward_simple(pool, skt, req, args)
  args.req = req

  local downstream_addr = pool.choose(args.key)
  if downstream_addr then
    apo.send(downstream_addr, "fwd", apo.self_address(),
             skt, pack.opcode(req, 'request'), args)

    return apo.recv()
  end

  return false -- TODO: send err response instead?
end

-- For binary commands that just do a broadcast scatter/gather.
--
local function forward_broadcast(pool, skt, req, args, skt_callback)
  local opcode = pack.opcode(req, 'request')

  args.req = req

  local n = 0
  pool.each(
    function(downstream_addr)
      apo.send(downstream_addr, "fwd", apo.self_address(),
               false, opcode, args, skt_callback)
      n = n + 1
    end)

  local oks = 0 -- TODO: Do something with oks count.
  for i = 1, n do
    if apo.recv() then
      oks = oks + 1
    end
  end

  local res =
    pack.create_response(opcode, {
      status = SUCCESS,
      opaque = pack.opaque(req, 'request')
    })
  return sock_send(skt, res)
end

------------------------------------------------------

local c = mpb.command
local a = {
  c.GET,
  c.SET,
  c.ADD,
  c.REPLACE,
  c.DELETE,
  c.INCREMENT,
  c.DECREMENT,
  c.GETQ,
  c.GETK,
  c.GETKQ,
  c.APPEND,
  c.PREPEND,
  c.STAT,
  c.SETQ,
  c.ADDQ,
  c.REPLACEQ,
  c.DELETEQ,
  c.INCREMENTQ,
  c.DECREMENTQ,
  c.FLUSHQ,
  c.APPENDQ,
  c.PREPENDQ
}

for i = 1, #a do
  msbp[a[i]] = forward_simple
end

------------------------------------------------------

msbp[mpb.command.FLUSH] =
  function(pool, skt, req, args)
    return forward_broadcast(pool, skt, req, args, nil)
  end

msbp[mpb.command.NOOP] =
  function(pool, skt, req, args)
    local function skt_callback(head, body)
      if pack.opcode(head, 'response') == mpb.command.NOOP then
        return true
      end

      local msg = head ..
                  (body.ext or "") ..
                  (body.key or "") ..
                  (body.data or "")

      return sock_send(skt, msg)
    end

    return forward_broadcast(pool, skt, req, args, skt_callback)
  end

------------------------------------------------------

msbp[mpb.command.QUIT] =
  function(pool, skt, req, args)
    return false
  end

msbp[mpb.command.QUITQ] = msbp[mpb.command.QUIT]

------------------------------------------------------

msbp[mpb.command.VERSION] =
  function(pool, skt, req, args)
  end

msbp[mpb.command.STAT] =
  function(pool, skt, req, args)
  end

msbp[mpb.command.SASL_LIST_MECHS] =
  function(pool, skt, req, args)
  end

msbp[mpb.command.SASL_AUTH] =
  function(pool, skt, req, args)
  end

msbp[mpb.command.SASL_STEP] =
  function(pool, skt, req, args)
  end

msbp[mpb.command.BUCKET] =
  function(pool, skt, req, args)
  end

