memcached_server_binary_dict = {}

local msbd = memcached_server_binary_dict
local mpb  = memcached_protocol_binary
local pack = mpb.pack

local SUCCESS = mpb.response_stats.SUCCESS

msbd[mpb.command.GET] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.SET] =
  function(dict, skt, req, args)
    dict.tbl[args.key] = args.data
    local res =
      pack.create_response(mpb.command.SET, {
        status = SUCCESS,
        opaque = pack.opaque(req, 'request')
      })
    return sock_send(skt, res)
  end

msbd[mpb.command.ADD] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.REPLACE] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.DELETE] =
  function(dict, skt, req, args)
    dict.tbl[args.key] = nil
    local res =
      pack.create_response(mpb.command.DELETE, {
        status = SUCCESS,
        opaque = pack.opaque(req, 'request')
      })
    return sock_send(skt, res)
  end

msbd[mpb.command.INCREMENT] =
  function(dict, skt, req, args)
    local num = tonumber(dict.tbl[args.key])
    local num = num + tonumber(args.amount)
    dict.tbl[args.key] = tostring(num)

    local res =
      pack.create_response(mpb.command.INCREMENT, {
        status = SUCCESS,
        opaque = pack.opaque(req, 'request'),
        amount = dict.tbl[args.key] 
      })
    return sock_send(skt, res)
  end

msbd[mpb.command.DECREMENT] =
  function(dict, skt, req, args)
    local num = tonumber(dict.tbl[args.key])
    local num = num - tonumber(args.amount)
    dict.tbl[args.key] = tostring(num)

    local res =
      pack.create_response(mpb.command.DECREMENT, {
        status = SUCCESS,
        opaque = pack.opaque(req, 'request'),
        amount = dict.tbl[args.key] 
      })
    return sock_send(skt, res)
  end

msbd[mpb.command.QUIT] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.FLUSH] =
  function(dict, skt, req, args)
    dict.tbl = {}
    local res =
      pack.create_response(mpb.command.FLUSH, {
        status = SUCCESS,
        opaque = pack.opaque(req, 'request')
      })
    return sock_send(skt, res)
  end

msbd[mpb.command.GETQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.NOOP] =
  function(dict, skt, req, args)
    local res =
      pack.create_response(mpb.command.NOOP, {
        status = SUCCESS,
        opaque = pack.opaque(req, 'request')
      })
    return sock_send(skt, res)
  end

msbd[mpb.command.VERSION] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.GETK] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.GETKQ] =
  function(dict, skt, req, args)
    local data = dict.tbl[args.key]
    if data then
      local res =
        pack.create_response(mpb.command.GETKQ, {
          status = SUCCESS,
          opaque = pack.opaque(req, 'request'),
          key    = args.key,
          ext    = string.char(0, 0, 0, 0),
          data   = data
        })
      return sock_send(skt, res)
    end
    return true
  end

msbd[mpb.command.APPEND] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.PREPEND] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.STAT] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.SETQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.ADDQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.REPLACEQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.DELETEQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.INCREMENTQ] =
  function(dict, skt, req, args)
    local num = tonumber(dict.tbl[args.key])
    local num = num + tonumber(args.amount)
    dict.tbl[args.key] = tostring(num)

    local res =
      pack.create_response(mpb.command.INCREMENT, {
        status = SUCCESS,
        opaque = pack.opaque(req, 'request'),
        amount = dict.tbl[args.key] 
      })
    return sock_send(skt, res)
  end

msbd[mpb.command.DECREMENTQ] =
  function(dict, skt, req, args)
    local num = tonumber(dict.tbl[args.key])
    local num = num + tonumber(args.amount)
    dict.tbl[args.key] = tostring(num)

    local res =
      pack.create_response(mpb.command.INCREMENT, {
        status = SUCCESS,
        opaque = pack.opaque(req, 'request'),
        amount = dict.tbl[args.key] 
      })
    return sock_send(skt, res)
  end

msbd[mpb.command.QUITQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.FLUSHQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.APPENDQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.PREPENDQ] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.SASL_LIST_MECHS] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.SASL_AUTH] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.SASL_STEP] =
  function(dict, skt, req, args)
  end

msbd[mpb.command.BUCKET] =
  function(dict, skt, req, args)
  end

