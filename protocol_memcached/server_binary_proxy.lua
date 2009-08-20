-- Need a noreply version of client_binary api.
-- Also, need to handle opaque's right.
--
memcached_server_binary_proxy = {}

local msbp = memcached_server_binary_proxy
local mpb  = memcached_protocol_binary
local pack = mpb.pack

local SUCCESS = mpb.response_stats.SUCCESS

-- Translators for binary upstream to different downstreams.
--
local b2x = {
  ascii = -- Downstream is ascii.
    function(downstream, skt, cmd, args, response_filter)
      local function response(head, body)
        if (not response_filter) or
           response_filter(head, body) then
          return skt and
                 (head and
                  sock_send(skt, head .. "\r\n")) and
                 ((not body) or
                  sock_send(skt, body.data .. "\r\n"))
        end

        return true
      end
    end,

  binary = -- Downstream is binary.
    function(downstream, skt, cmd, args, response_filter)
      local function response(head, body)
        if (not response_filter) or
           response_filter(head, body) then
          if skt then
            local msg = head ..
                        (body.ext or "") ..
                        (body.key or "") ..
                        (body.data or "")

            return sock_send(skt, msg)
          end
        end

        return true
      end

      apo.send(downstream.addr, "fwd", apo.self_address(),
               response, cmd, args)

      return true
    end
}

------------------------------------------------------

-- For binary commands that just do a simple command forward.
--
local function forward_simple(pool, skt, req, args)
  args.req = req

  local downstream = pool.choose(args.key)
  if downstream and
     downstream.addr then
    if b2x[downstream.kind](downstream, skt,
                            pack.opcode(req, 'request'), args) then
      return apo.recv()
    end
  end

  return false -- TODO: send err response instead?
end

-- For binary commands that just do a broadcast scatter/gather.
--
local function forward_broadcast(pool, skt, req, args, response_filter)
  local opcode = pack.opcode(req, 'request')

  args.req = req

  local n = 0

  pool.each(
    function(downstream)
      if b2x[downstream.kind](downstream, skt, opcode, args, response_filter) then
        n = n + 1
      end
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

local function forward_broadcast_filter(opcode_filter)
  local function response_filter(head, body)
    return pack.opcode(head, 'response') ~= opcode_filter
  end

  local function f(pool, skt, req, args)
    return forward_broadcast(pool, skt, req, args, response_filter)
  end

  return f
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

msbp[mpb.command.FLUSH] = forward_broadcast_filter(mpb.command.FLUSH)

msbp[mpb.command.NOOP] = forward_broadcast_filter(mpb.command.NOOP)

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

